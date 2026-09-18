import 'package:flutter/material.dart';

import '../utils/playlist_colors.dart';

/// Icono cuadrado de una playlist, con el color que el usuario le haya dado.
///
/// Spec "Icono de playlist con color". Sin color asignado se mantiene el
/// contenedor neutro que ya usaba la lista de playlists, de modo que las
/// playlists creadas antes de esta spec se siguen viendo igual.
class PlaylistIcon extends StatelessWidget {
  const PlaylistIcon({this.colorIndex, this.size = 40, super.key});

  /// Índice dentro de `appPlaylistIconColors`; `null` = sin color propio.
  final int? colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = PlaylistColors.of(colorIndex);
    final containerColor = color == null
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : PlaylistColors.containerColor(color);
    return Container(
      width: size,
      height: size,
      color: containerColor,
      child: Icon(
        Icons.queue_music,
        // La spec "Formas de los componentes" no admite bordes redondeados:
        // el contenedor es rectangular como el resto de componentes.
        color: color == null ? null : PlaylistColors.iconColor(color),
      ),
    );
  }
}
