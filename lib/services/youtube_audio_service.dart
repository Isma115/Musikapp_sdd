import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeVideo {
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String author;
  final Duration? duration;
  final String thumbnailUrl;

  Uri get watchUri =>
      Uri.https('www.youtube.com', '/watch', <String, String>{'v': id});
}

/// Estrategia de descarga ofrecida en la vista de Descargar.
///
/// Cada valor ordena de forma distinta los flujos de audio disponibles para
/// que, si un método falla, el usuario pueda reintentar con otro sin cambiar
/// el resto del flujo (búsqueda, lista y guardado en Descargas).
enum DownloadMethod { automatic, highQuality, lowQuality, compatible }

extension DownloadMethodLabel on DownloadMethod {
  String get label {
    switch (this) {
      case DownloadMethod.automatic:
        return 'Automático';
      case DownloadMethod.highQuality:
        return 'Calidad alta';
      case DownloadMethod.lowQuality:
        return 'Calidad baja';
      case DownloadMethod.compatible:
        return 'Compatible';
    }
  }

  String get description {
    switch (this) {
      case DownloadMethod.automatic:
        return 'Prueba varios flujos, de mayor a menor bitrate.';
      case DownloadMethod.highQuality:
        return 'Prioriza el audio con mayor bitrate disponible.';
      case DownloadMethod.lowQuality:
        return 'Prueba primero los flujos más ligeros.';
      case DownloadMethod.compatible:
        return 'Prueba primero los flujos muxed compatibles.';
    }
  }
}

class YouTubeAudioService {
  YouTubeAudioService() : _client = YoutubeExplode();

  final YoutubeExplode _client;

  // Mejora de descarga: tiempos máximos por etapa. Antes una etapa atascada
  // (típico en vídeos de más de 1 minuto) dejaba la descarga colgada sin
  // probar el siguiente flujo; ahora falla rápido y se intenta otro método.
  static const _searchTimeout = Duration(seconds: 20);
  static const _manifestTimeout = Duration(seconds: 30);
  static const _streamTimeout = Duration(seconds: 120);
  static const _convertTimeout = Duration(seconds: 120);

  Future<List<YouTubeVideo>> search(String query) async {
    final results = await _client.search
        .search(query)
        .timeout(_searchTimeout);
    return results
        .map(
          (video) => YouTubeVideo(
            id: video.id.value,
            title: video.title,
            author: video.author,
            duration: video.duration,
            thumbnailUrl: video.thumbnails.highResUrl,
          ),
        )
        .toList(growable: false);
  }

  /// Descarga el audio de [video] y lo convierte a MP3 en Descargas.
  ///
  /// [method] selecciona el orden de los flujos candidatos. El modo
  /// [DownloadMethod.automatic] prueba primero los flujos solo-audio de mayor
  /// a menor bitrate y después los muxed como alternativa si un método falla.
  /// Los demás valores permiten reintentar manualmente con otra estrategia.
  ///
  /// [onProgress] notifica el progreso de la descarga del flujo (0.0 a 1.0).
  /// Solo cubre la descarga de bytes; la conversión posterior a MP3 mantiene
  /// el último valor notificado.
  Future<File> downloadAsMp3(
    YouTubeVideo video, {
    DownloadMethod method = DownloadMethod.automatic,
    void Function(double progress)? onProgress,
  }) async {
    final downloadDirectory = await _downloadDirectory();
    final baseName = _safeFileName(video.title);
    final outputStem = await _uniqueStem(downloadDirectory, baseName);
    final outputFile = File(p.join(downloadDirectory.path, '$outputStem.mp3'));

    final manifest = await _client.videos.streams
        .getManifest(video.id)
        .timeout(_manifestTimeout);
    final candidates = _orderedCandidates(manifest, method);
    if (candidates.isEmpty) {
      throw StateError('El vídeo no ofrece una pista de audio descargable.');
    }

    Object? lastError;
    for (final candidate in candidates) {
      final sourceExtension = candidate.container.name.toLowerCase();
      final sourceFile = File(
        p.join(
          downloadDirectory.path,
          '$outputStem.tag${candidate.tag}.$sourceExtension',
        ),
      );
      try {
        await _downloadStream(candidate, sourceFile, onProgress: onProgress);
        await _convertToMp3(sourceFile, outputFile);
        return outputFile;
      } on Object catch (error) {
        lastError = error;
        await _deleteQuietly(outputFile);
      } finally {
        await _deleteQuietly(sourceFile);
      }
    }

    Error.throwWithStackTrace(
      StateError(
        'No se pudo descargar el audio con ${method.label}. '
        '${_describeError(lastError)}',
      ),
      StackTrace.current,
    );
  }

  void dispose() => _client.close();

  List<AudioStreamInfo> _orderedCandidates(
    StreamManifest manifest,
    DownloadMethod method,
  ) {
    final audioOnly = manifest.audioOnly.sortByBitrate();
    final muxed = manifest.muxed.sortByBitrate();
    switch (method) {
      case DownloadMethod.automatic:
        return <AudioStreamInfo>[...audioOnly, ...muxed];
      case DownloadMethod.highQuality:
        // Prioriza solo-audio de mayor a menor; si no hay, usa muxed.
        return <AudioStreamInfo>[
          ...audioOnly,
          if (audioOnly.isEmpty) ...muxed,
        ];
      case DownloadMethod.lowQuality:
        // Mismo conjunto solo-audio pero empezando por el más ligero.
        final lightestFirst = audioOnly.reversed.toList(growable: false);
        return <AudioStreamInfo>[
          ...lightestFirst,
          if (lightestFirst.isEmpty) ...muxed.reversed,
        ];
      case DownloadMethod.compatible:
        return <AudioStreamInfo>[...muxed, ...audioOnly];
    }
  }

  Future<void> _downloadStream(
    AudioStreamInfo stream,
    File target, {
    void Function(double progress)? onProgress,
  }) async {
    await _deleteQuietly(target);
    final totalBytes = stream.size.totalBytes;
    // Sin tamaño conocido no se puede calcular porcentaje: descarga clásica.
    if (totalBytes <= 0) {
      final sink = target.openWrite();
      try {
        await _client.videos.streams
            .get(stream)
            .pipe(sink)
            .timeout(_streamTimeout);
        await sink.flush();
      } finally {
        await sink.close();
      }
    } else {
      // Copia manual para notificar progreso (recibidos / total).
      // El timeout es por inactividad entre trozos: una descarga lenta pero
      // que avanza no se corta, y una atascada falla y prueba otro flujo.
      final sink = target.openWrite();
      try {
        onProgress?.call(0);
        var receivedBytes = 0;
        var lastReported = -1.0;
        await for (final chunk in _client.videos.streams
            .get(stream)
            .timeout(_streamTimeout)) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          if ((progress - lastReported).abs() >= 0.01 || progress >= 1.0) {
            lastReported = progress;
            onProgress?.call(progress);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    }
    if (!await target.exists() || await target.length() == 0) {
      throw StateError('La descarga quedó vacía, se prueba otro método.');
    }
  }

  Future<void> _convertToMp3(File source, File output) async {
    // Bitrate fijo para que la conversión de audios largos sea más rápida y
    // de tamaño predecible; se mantiene el segundo comando como alternativa
    // compatible con el mismo bitrate.
    final commands = <String>[
      '-y -i ${_shellQuote(source.path)} '
          '-vn -codec:a libmp3lame -b:a 128k ${_shellQuote(output.path)}',
      '-y -i ${_shellQuote(source.path)} '
          '-vn -codec:a libmp3lame -b:a 128k -ar 44100 -ac 2 '
          '${_shellQuote(output.path)}',
    ];
    Object? lastError;
    for (final command in commands) {
      await _deleteQuietly(output);
      try {
        final session = await FFmpegKit.execute(
          command,
        ).timeout(_convertTimeout);
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode) &&
            await output.exists() &&
            await output.length() > 0) {
          return;
        }
        lastError = StateError('No se pudo convertir el audio a MP3.');
      } on Object catch (error) {
        lastError = error;
      }
    }
    Error.throwWithStackTrace(
      lastError ?? StateError('No se pudo convertir el audio a MP3.'),
      StackTrace.current,
    );
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on Object {
      // La limpieza no debe ocultar el error original de la descarga.
    }
  }

  String _describeError(Object? error) {
    if (error == null) {
      return 'Inténtalo de nuevo con otro método.';
    }
    if (error is TimeoutException) {
      return 'La descarga tardó demasiado, se prueba otro método.';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Inténtalo de nuevo con otro método.';
  }

  Future<Directory> _downloadDirectory() async {
    final candidates = <Directory>[];
    if (Platform.isAndroid) {
      candidates.add(Directory('/storage/emulated/0/Download'));
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        candidates.add(downloads);
      }
    } on UnsupportedError {
      // Se usa la memoria interna si la plataforma no ofrece Descargas.
    } on Object {
      // El proveedor puede no estar disponible durante un test o el arranque.
    }

    try {
      candidates.add(await getApplicationDocumentsDirectory());
    } on Object {
      // No hay una ubicación local disponible.
    }

    for (final candidate in candidates) {
      try {
        await candidate.create(recursive: true);
        final probe = File(p.join(candidate.path, '.sdd_music_write_test'));
        await probe.writeAsString('');
        await probe.delete();
        return candidate;
      } on Object {
        // Prueba la siguiente ubicación disponible.
      }
    }

    throw FileSystemException('No hay una carpeta de Descargas disponible.');
  }

  Future<String> _uniqueStem(Directory directory, String baseName) async {
    var stem = baseName;
    var suffix = 1;
    while (await File(p.join(directory.path, '$stem.mp3')).exists()) {
      stem = '$baseName ($suffix)';
      suffix++;
    }
    return stem;
  }

  String _safeFileName(String title) {
    final safe = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safe.isEmpty) {
      return 'audio_${DateTime.now().millisecondsSinceEpoch}';
    }
    // Títulos muy largos provocan fallos al crear el fichero en Descargas;
    // se recorta de forma conservadora sin cambiar el resto del flujo.
    const maxLength = 80;
    if (safe.length <= maxLength) {
      return safe;
    }
    return safe.substring(0, maxLength).trim();
  }

  String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
}
