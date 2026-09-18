import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';

class MusicScanner {
  static const _permissionChannel = MethodChannel(
    'sdd_music_simple/storage_permissions',
  );

  static const _audioExtensions = <String>{
    '.aac',
    '.flac',
    '.m4a',
    '.mp3',
    '.ogg',
    '.opus',
    '.wav',
    '.wma',
  };

  Future<List<AudioTrack>> scan() async {
    try {
      await _requestAudioAccess();
      final directories = await _musicDirectories();
      final tracksByPath = <String, AudioTrack>{};

      for (final directory in directories) {
        try {
          if (!await directory.exists()) {
            continue;
          }
          await for (final entity in directory.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is! File || !_isAudioFile(entity.path)) {
              continue;
            }
            tracksByPath[entity.path] = AudioTrack.fromPath(entity.path);
          }
        } on FileSystemException {
          // Una carpeta sin permisos no impide escanear las demás.
        }
      }

      final tracks = tracksByPath.values.toList()
        ..sort(
          (left, right) =>
              left.name.toLowerCase().compareTo(right.name.toLowerCase()),
        );
      return tracks;
    } on Object {
      // El escaneo es una ayuda de la biblioteca; la app sigue siendo usable
      // aunque el sistema no exponga alguna de las carpetas.
      return const <AudioTrack>[];
    }
  }

  bool _isAudioFile(String path) =>
      _audioExtensions.contains(p.extension(path).toLowerCase());

  Future<void> _requestAudioAccess() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _permissionChannel.invokeMethod<bool>('requestAudioAccess');
    } on MissingPluginException {
      // Los tests y plataformas sin implementación nativa siguen con el escaneo.
    } on PlatformException {
      // El resultado de la búsqueda será vacío si el sistema deniega el acceso.
    }
  }

  Future<List<Directory>> _musicDirectories() async {
    if (Platform.isAndroid) {
      // Android usa Download en singular para la carpeta pública del usuario.
      return <Directory>[
        Directory('/storage/emulated/0/Documents'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Music'),
      ];
    }

    final directories = <Directory>[];
    final documents = await getApplicationDocumentsDirectory();
    directories.add(documents);

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        directories.add(downloads);
      }
    } on UnsupportedError {
      // Algunas plataformas no tienen una carpeta pública de descargas.
    } on MissingPluginException {
      // La implementación se registra al ejecutar la app en un dispositivo.
    }

    directories.add(Directory(p.join(documents.parent.path, 'Music')));
    return directories;
  }
}
