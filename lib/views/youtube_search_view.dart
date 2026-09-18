import 'package:flutter/material.dart';

import '../services/youtube_audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_decoration.dart';
import '../widgets/empty_state.dart';
import '../widgets/youtube_tiles.dart';

/// Sección de la búsqueda de YouTube (descarga o visor).
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
enum YouTubeSection { download, viewer }

/// Búsqueda superior + lista de resultados de YouTube.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
class YouTubeSearchView extends StatelessWidget {
  const YouTubeSearchView({
    required this.section,
    required this.title,
    required this.controller,
    required this.results,
    required this.isSearching,
    required this.error,
    required this.downloadingVideoIds,
    required this.downloadProgress,
    required this.streamingVideoIds,
    required this.onSearch,
    required this.onDownload,
    required this.onShowDownloadOptions,
    required this.onOpenVideo,
    required this.onPlayVideo,
    super.key,
  });

  final YouTubeSection section;
  final String title;
  final TextEditingController controller;
  final List<YouTubeVideo> results;
  final bool isSearching;
  final String? error;
  final Set<String> downloadingVideoIds;
  final Map<String, double> downloadProgress;
  final Set<String> streamingVideoIds;
  final ValueChanged<YouTubeSection> onSearch;
  final ValueChanged<YouTubeVideo> onDownload;
  final ValueChanged<YouTubeVideo> onShowDownloadOptions;
  final ValueChanged<YouTubeVideo> onOpenVideo;
  final ValueChanged<YouTubeVideo> onPlayVideo;

  @override
  Widget build(BuildContext context) {
    final isDownload = section == YouTubeSection.download;
    // Spec "Iconos atractivos": el fondo decora con símbolos grandes del área.
    // Descargar usa el acento azul de su pestaña y el visor el violeta, así cada
    // vista mantiene su identidad aunque compartan estructura.
    return BackgroundDecor(
      icons: isDownload
          ? const <IconData>[
              Icons.download,
              Icons.play_circle_fill,
              Icons.library_music,
            ]
          : const <IconData>[
              Icons.ondemand_video,
              Icons.play_circle_fill,
              Icons.headphones,
            ],
      accent: isDownload ? appSectionAccents[1] : AppColors.tertiary,
      child: _buildContent(context, isDownload),
    );
  }

  Widget _buildContent(BuildContext context, bool isDownload) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(section),
            decoration: InputDecoration(
              labelText: title,
              hintText: 'Escribe un término de búsqueda',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: isSearching ? null : () => onSearch(section),
                tooltip: 'Buscar',
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (isSearching) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: results.isEmpty && !isSearching
              ? const EmptyState(
                  icon: Icons.ondemand_video,
                  message: 'Busca un vídeo para ver los resultados.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final video = results[index];
                    return isDownload
                        ? YouTubeDownloadTile(
                            video: video,
                            isDownloading: downloadingVideoIds.contains(
                              video.id,
                            ),
                            progress: downloadProgress[video.id],
                            onDownload: () => onDownload(video),
                            onShowOptions: () => onShowDownloadOptions(video),
                          )
                        : YouTubeLinkTile(
                            video: video,
                            isPlaying: streamingVideoIds.contains(video.id),
                            onOpen: () => onOpenVideo(video),
                            onPlay: () => onPlayVideo(video),
                          );
                  },
                ),
        ),
      ],
    );
  }
}
