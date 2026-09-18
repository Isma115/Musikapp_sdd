import 'package:flutter/material.dart';

import '../services/youtube_audio_service.dart';
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
    required this.onSearch,
    required this.onDownload,
    required this.onShowDownloadOptions,
    required this.onOpenVideo,
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
  final ValueChanged<YouTubeSection> onSearch;
  final ValueChanged<YouTubeVideo> onDownload;
  final ValueChanged<YouTubeVideo> onShowDownloadOptions;
  final ValueChanged<YouTubeVideo> onOpenVideo;

  @override
  Widget build(BuildContext context) {
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
                    return section == YouTubeSection.download
                        ? YouTubeDownloadTile(
                            video: video,
                            isDownloading: downloadingVideoIds.contains(
                              video.id,
                            ),
                            progress: downloadProgress[video.id],
                            onDownload: () => onDownload(video),
                            onShowOptions: () =>
                                onShowDownloadOptions(video),
                          )
                        : YouTubeLinkTile(
                            video: video,
                            onOpen: () => onOpenVideo(video),
                          );
                  },
                ),
        ),
      ],
    );
  }
}
