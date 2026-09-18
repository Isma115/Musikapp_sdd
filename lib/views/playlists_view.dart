import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/empty_state.dart';

/// Vista de lista de playlists.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
class PlaylistsView extends StatelessWidget {
  const PlaylistsView({
    required this.playlists,
    required this.onCreatePlaylist,
    required this.onOpenPlaylist,
    super.key,
  });

  final List<Playlist> playlists;
  final VoidCallback onCreatePlaylist;
  final ValueChanged<int> onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onCreatePlaylist,
            icon: const Icon(Icons.add),
            label: const Text('+ Añadir Playlist'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: playlists.isEmpty
                ? const EmptyState(
                    icon: Icons.queue_music,
                    message: 'Todavía no hay playlists creadas.',
                  )
                : ListView.separated(
                    itemCount: playlists.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.queue_music),
                          ),
                          title: Text(playlist.name),
                          subtitle: Text(
                            '${playlist.tracks.length} '
                            '${playlist.tracks.length == 1 ? 'canción' : 'canciones'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onOpenPlaylist(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
