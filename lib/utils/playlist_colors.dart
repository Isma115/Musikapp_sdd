import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Paleta de colores disponible para el icono de cada playlist.
///
/// Spec "Icono de playlist con color": permite darle color al icono de cada
/// playlist. Se define una paleta cerrada (en lugar de un selector de color
/// libre) para que la elección del usuario nunca rompa la paleta oscura
/// azul/morado/violeta que fijan las specs "Paleta de colores" y "Mejora de
/// paleta de colores": los tonos base de la aplicación abren la lista y el
/// resto son tonos igualmente apagados que mantienen la interfaz sin saturar.
const List<Color> appPlaylistIconColors = <Color>[
  AppColors.primary,
  AppColors.secondary,
  AppColors.tertiary,
  Color(0xFF7E6BE0),
  Color(0xFF4E8FB5),
  Color(0xFF5FA98F),
  Color(0xFFB98F5A),
  Color(0xFFC46F8C),
];

/// Utilidades de conversión entre el color guardado en disco y la interfaz.
///
/// Se persiste el índice dentro de [appPlaylistIconColors] y no el valor del
/// color: así un ajuste posterior de la paleta no deja playlists con tonos
/// fuera de ella.
abstract final class PlaylistColors {
  /// Color elegido, o `null` si la playlist no tiene ninguno asignado.
  static Color? of(int? iconColorIndex) {
    if (iconColorIndex == null ||
        iconColorIndex < 0 ||
        iconColorIndex >= appPlaylistIconColors.length) {
      return null;
    }
    return appPlaylistIconColors[iconColorIndex];
  }

  /// Valida un índice recibido desde el almacenamiento.
  /// Devuelve `null` cuando el valor no es un índice de la paleta.
  static int? normalizeIndex(int? iconColorIndex) =>
      of(iconColorIndex) == null ? null : iconColorIndex;

  /// Tono del contenedor cuadrado que envuelve al icono: el propio color
  /// elegido muy oscurecido, para que la superficie siga siendo discreta.
  static Color containerColor(Color color) => Color.alphaBlend(
    color.withValues(alpha: 0.22),
    AppColors.surfaceContainer,
  );

  /// Tono del icono sobre [containerColor]: el color elegido aclarado, igual
  /// que hacen los iconos de la navegación inferior con el acento de su área,
  /// para que se lea sobre el contenedor oscuro.
  static Color iconColor(Color color) =>
      Color.lerp(color, Colors.white, 0.35) ?? color;
}
