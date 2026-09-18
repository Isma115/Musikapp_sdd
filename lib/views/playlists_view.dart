import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../utils/playlist_colors.dart';
import '../widgets/background_decoration.dart';
import '../widgets/empty_state.dart';
import '../widgets/playlist_icon.dart';
import '../widgets/playlist_icon_picker.dart';

/// Vista de lista de playlists.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento.
class PlaylistsView extends StatelessWidget {
  const PlaylistsView({
    required this.playlists,
    required this.onCreatePlaylist,
    required this.onOpenPlaylist,
    required this.onChangeIconColor,
    super.key,
  });

  /// Símbolos grandes del fondo (spec "Iconos atractivos").
  static const _backgroundIcons = <IconData>[
    Icons.queue_music,
    Icons.library_music,
    Icons.music_note,
  ];

  final List<Playlist> playlists;
  final VoidCallback onCreatePlaylist;
  final ValueChanged<int> onOpenPlaylist;

  /// Cambia el color del icono de una playlist (spec "Icono de playlist con
  /// color"); `null` lo deja sin color propio.
  final void Function(int index, int? iconColorIndex) onChangeIconColor;

  @override
  Widget build(BuildContext context) {
    return BackgroundDecor(
      icons: _backgroundIcons,
      accent: appSectionAccents[0],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.add),
              // Spec "El botón de 'Añadir x' no tiene que tener el botón '+'
              // duplicado": el signo ya lo aporta el icono, así que el texto
              // solo lleva la acción.
              label: const Text('Añadir Playlist'),
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
                            // Spec "Icono de playlist con color": la portada
                            // muestra el color elegido por el usuario.
                            leading: PlaylistIcon(
                              colorIndex: playlist.iconColorIndex,
                            ),
                            title: Text(playlist.name),
                            subtitle: Text(
                              '${playlist.tracks.length} '
                              '${playlist.tracks.length == 1 ? 'canción' : 'canciones'}',
                            ),
                            trailing: PopupMenuButton<_PlaylistAction>(
                              tooltip: 'Opciones de la playlist',
                              onSelected: (action) {
                                switch (action) {
                                  case _PlaylistAction.iconColor:
                                    _pickIconColor(context, index, playlist);
                                  case _PlaylistAction.removeIconColor:
                                    onChangeIconColor(index, null);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<_PlaylistAction>(
                                  value: _PlaylistAction.iconColor,
                                  child: Text('Color del icono'),
                                ),
                                if (PlaylistColors.of(
                                      playlist.iconColorIndex,
                                    ) !=
                                    null)
                                  const PopupMenuItem<_PlaylistAction>(
                                    value: _PlaylistAction.removeIconColor,
                                    child: Text('Quitar color'),
                                  ),
                              ],
                            ),
                            onTap: () => onOpenPlaylist(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIconColor(
    BuildContext context,
    int index,
    Playlist playlist,
  ) async {
    final selected = await showPlaylistIconColorPicker(
      context: context,
      currentIndex: playlist.iconColorIndex,
      playlistName: playlist.name,
    );
    // `null` = el diálogo se cerró sin elegir: no se toca la playlist.
    if (selected == null) {
      return;
    }
    onChangeIconColor(
      index,
      selected == removePlaylistIconColor ? null : selected,
    );
  }
}

/// Acciones disponibles sobre la tarjeta de una playlist.
enum _PlaylistAction { iconColor, removeIconColor }
