import 'package:flutter/material.dart';

import '../services/youtube_audio_service.dart';
import '../utils/duration_format.dart';

/// Fila de resultado con botón de descarga a la izquierda.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
class YouTubeDownloadTile extends StatelessWidget {
  const YouTubeDownloadTile({
    required this.video,
    required this.isDownloading,
    required this.onDownload,
    required this.onShowOptions,
    this.progress,
    super.key,
  });

  final YouTubeVideo video;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onShowOptions;

  /// Progreso de descarga de 0.0 a 1.0. Si es nulo, la descarga aún no ha
  /// empezado a recibir bytes y se muestra el círculo indeterminado actual.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        onPressed: isDownloading ? null : onDownload,
        tooltip: 'Descargar audio',
        icon: isDownloading
            ? SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3, value: progress),
                    if (progress != null)
                      Text(
                        '${(progress! * 100).round()}%',
                        style: const TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              )
            : const Icon(Icons.download),
      ),
      title: Text(video.title),
      subtitle: Text('${video.author} · ${formatDuration(video.duration)}'),
      trailing: IconButton(
        onPressed: isDownloading ? null : onShowOptions,
        tooltip: 'Opciones de descarga',
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}

/// Fila de enlace a YouTube del visor.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
class YouTubeLinkTile extends StatelessWidget {
  const YouTubeLinkTile({
    required this.video,
    required this.isPlaying,
    required this.onOpen,
    required this.onPlay,
    super.key,
  });

  final YouTubeVideo video;
  final bool isPlaying;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        onPressed: isPlaying ? null : onPlay,
        tooltip: 'Reproducir audio de YouTube',
        icon: isPlaying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
      ),
      title: Text(video.title),
      subtitle: Text('${video.author} · ${formatDuration(video.duration)}'),
      trailing: IconButton(
        onPressed: onOpen,
        tooltip: 'Abrir enlace de YouTube',
        icon: const Icon(Icons.open_in_new),
      ),
      onTap: onOpen,
    );
  }
}
