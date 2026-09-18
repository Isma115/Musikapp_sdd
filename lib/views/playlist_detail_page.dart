import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/background_decoration.dart';
import '../widgets/empty_state.dart';
import '../widgets/playlist_icon.dart';
import '../widgets/playlist_icon_picker.dart';

/// Detalle de playlist con altura fija por canción (64px).
/// Extraído de `main.dart` sin cambios visuales ni de comportamiento: cada
/// canción se reproduce con el botón o pulsando la fila.
///
/// Spec "Fix: Sección de reproducción": este detalle ya no se empuja como ruta
/// propia; el shell lo muestra dentro de su cuerpo, debajo de su AppBar (que
/// pasa a titular la playlist) y por encima de la barra de reproducción. Así el
/// cuadro de reproducción aparece en cuanto suena la canción, sin tener que
/// volver a la lista de playlists. Se conserva el `Scaffold` interno, sin
/// AppBar, para no alterar el comportamiento de los avisos (`SnackBar`).
class PlaylistDetailPage extends StatefulWidget {
  const PlaylistDetailPage({
    required this.playlist,
    required this.availableTracks,
    required this.onTracksChanged,
    this.onPlayQueue,
    this.onIconColorChanged,
    super.key,
  });

  final Playlist playlist;
  final List<AudioTrack> availableTracks;
  final ValueChanged<List<AudioTrack>> onTracksChanged;
  final void Function(List<AudioTrack> queue, int index)? onPlayQueue;

  /// Cambia el color del icono de la playlist (spec "Icono de playlist con
  /// color"); `null` lo deja sin color propio.
  final ValueChanged<int?>? onIconColorChanged;

  @override
  State<PlaylistDetailPage> createState() => PlaylistDetailPageState();
}

class PlaylistDetailPageState extends State<PlaylistDetailPage> {
  static const _snackBarDuration = Duration(seconds: 3);

  /// Símbolos grandes del fondo (spec "Iconos atractivos").
  static const _backgroundIcons = <IconData>[
    Icons.music_note,
    Icons.album,
    Icons.graphic_eq,
  ];

  late List<AudioTrack> _tracks;

  @override
  void initState() {
    super.initState();
    _tracks = List<AudioTrack>.of(widget.playlist.tracks);
  }

  Future<void> _addSongs() async {
    final source = await showModalBottomSheet<_SongSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Seleccionar archivos de audio'),
              onTap: () => Navigator.of(sheetContext).pop(_SongSource.files),
            ),
            if (widget.availableTracks.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('Usar música escaneada'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_SongSource.scanned),
              ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) {
      return;
    }

    final selectedTracks = source == _SongSource.files
        ? await _pickAudioFiles()
        : await _pickScannedTracks();
    if (!mounted || selectedTracks == null || selectedTracks.isEmpty) {
      return;
    }

    final knownPaths = _tracks.map((track) => track.path).toSet();
    final newTracks = selectedTracks
        .where((track) => knownPaths.add(track.path))
        .toList(growable: false);
    if (newTracks.isEmpty) {
      _showMessage('Las canciones seleccionadas ya están en la playlist.');
      return;
    }

    setState(() => _tracks = <AudioTrack>[..._tracks, ...newTracks]);
    widget.onTracksChanged(_tracks);
  }

  Future<List<AudioTrack>?> _pickAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null) {
        return null;
      }
      return result.files
          .where((file) => file.path != null)
          .map((file) => AudioTrack.fromPath(file.path!, name: file.name))
          .toList(growable: false);
    } on Object {
      _showMessage('No se pudieron seleccionar archivos de audio.');
      return null;
    }
  }

  Future<List<AudioTrack>?> _pickScannedTracks() async {
    final selectedPaths = <String>{};
    return showDialog<List<AudioTrack>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Añadir canción'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SizedBox(
            width: double.maxFinite,
            height: 360,
            child: ListView.builder(
              itemCount: widget.availableTracks.length,
              itemBuilder: (context, index) {
                final track = widget.availableTracks[index];
                final selected = selectedPaths.contains(track.path);
                return CheckboxListTile(
                  value: selected,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(track.name),
                  subtitle: Text(track.path),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value ?? false) {
                        selectedPaths.add(track.path);
                      } else {
                        selectedPaths.remove(track.path);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: selectedPaths.isEmpty
                ? null
                : () => Navigator.of(dialogContext).pop(
                    widget.availableTracks
                        .where((track) => selectedPaths.contains(track.path))
                        .toList(growable: false),
                  ),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: _snackBarDuration),
      );
  }

  void _playTrackAt(int index) {
    final onPlayQueue = widget.onPlayQueue;
    if (onPlayQueue == null || index < 0 || index >= _tracks.length) {
      return;
    }
    onPlayQueue(List<AudioTrack>.unmodifiable(_tracks), index);
  }

  /// Spec "Icono de playlist con color": desde el propio detalle se puede
  /// cambiar el color del icono de la playlist abierta.
  Future<void> _pickIconColor() async {
    final onIconColorChanged = widget.onIconColorChanged;
    if (onIconColorChanged == null) {
      return;
    }
    final selected = await showPlaylistIconColorPicker(
      context: context,
      currentIndex: widget.playlist.iconColorIndex,
      playlistName: widget.playlist.name,
    );
    // `null` = el diálogo se cerró sin elegir: no se toca la playlist.
    if (selected == null) {
      return;
    }
    onIconColorChanged(selected == removePlaylistIconColor ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final onIconColorChanged = widget.onIconColorChanged;
    return BackgroundDecor(
      icons: _backgroundIcons,
      accent: appSectionAccents[0],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addSongs,
                    icon: const Icon(Icons.add),
                    // Spec "El botón de 'Añadir x' no tiene que tener el botón
                    // '+' duplicado": el signo ya lo aporta el icono.
                    label: const Text('Añadir canción'),
                  ),
                ),
                if (onIconColorChanged != null) ...[
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'Color del icono',
                    child: InkWell(
                      onTap: _pickIconColor,
                      child: PlaylistIcon(
                        colorIndex: widget.playlist.iconColorIndex,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tracks.isEmpty
                  ? const EmptyState(
                      icon: Icons.music_note,
                      message: 'Esta playlist todavía no tiene canciones.',
                    )
                  : ListView.separated(
                      itemCount: _tracks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => SizedBox(
                        height: 64,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          leading: IconButton(
                            onPressed: () => _playTrackAt(index),
                            tooltip: 'Reproducir canción',
                            icon: const Icon(Icons.play_arrow),
                          ),
                          title: Text(
                            _tracks[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _tracks[index].path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _playTrackAt(index),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SongSource { files, scanned }
