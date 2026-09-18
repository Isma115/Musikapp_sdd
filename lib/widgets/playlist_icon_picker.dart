import 'package:flutter/material.dart';

import '../utils/playlist_colors.dart';

/// Selector del color del icono de una playlist.
///
/// Spec "Icono de playlist con color". El valor devuelto es el índice elegido
/// dentro de la paleta de la aplicación (`appPlaylistIconColors`), o
/// [removePlaylistIconColor] cuando se pulsa "Quitar color". Para distinguir
/// "quitar el color" de "cerrar sin cambios" el diálogo devuelve ese valor
/// entero en lugar de `null`, de forma que cancelar (devolver `null`) nunca
/// modifica la playlist.
Future<int?> showPlaylistIconColorPicker({
  required BuildContext context,
  required int? currentIndex,
  required String playlistName,
}) {
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Color del icono ($playlistName)'),
      content: SingleChildScrollView(
        child: IconColorSwatchRow(
          selectedIndex: currentIndex,
          onSelected: (index) => Navigator.of(dialogContext).pop(index),
        ),
      ),
      actions: [
        if (PlaylistColors.of(currentIndex) != null)
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(removePlaylistIconColor),
            child: const Text('Quitar color'),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Valor devuelto por [showPlaylistIconColorPicker] al quitar el color.
const int removePlaylistIconColor = -1;

/// Fila de muestras de color reutilizada por el diálogo de nueva playlist y
/// por el selector de color del icono.
class IconColorSwatchRow extends StatelessWidget {
  const IconColorSwatchRow({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// Índice seleccionado; `null` = sin color propio.
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Muestra neutra: deja la playlist sin color propio.
        _ColorSwatch(
          color: null,
          selected: PlaylistColors.of(selectedIndex) == null,
          onTap: () => onSelected(removePlaylistIconColor),
        ),
        for (var index = 0; index < appPlaylistIconColors.length; index++)
          _ColorSwatch(
            color: appPlaylistIconColors[index],
            selected: selectedIndex == index,
            onTap: () => onSelected(index),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        color: color == null
            ? colorScheme.surfaceContainerHighest
            : PlaylistColors.containerColor(color!),
        // La selección se marca con un borde claro y grueso del propio color,
        // no con formas redondeadas ni con un check que tape la muestra.
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colorScheme.onSurface : colorScheme.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            Icons.queue_music,
            size: 20,
            color: color == null ? null : PlaylistColors.iconColor(color!),
          ),
        ),
      ),
    );
  }
}
