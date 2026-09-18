/// Tema oscuro azul/morado/violeta con componentes rectangulares.
///
/// Specs que fija este fichero:
/// * "Paleta de colores": modo oscuro en tonos azules, morados y violetas.
/// * "Mejora de paleta de colores": paleta más diversa y moderna, pero sin
///   saturar ni sobrecargar.
/// * "Formas de los componentes": sin bordes redondeados, todo rectangular.
///
/// Cómo se consigue la variedad sin sobrecargar:
/// * Se parte de una semilla violeta con el algoritmo tonal de Material 3, que
///   genera familias armónicas (morado, azul y violeta) de croma medio.
/// * A los tres colores de acento se les asignan los tres grupos de la
///   navegación inferior (Playlists, Descargar, Recomendaciones) para que cada
///   área tenga identidad propia, y el visor de YouTube reutiliza el acento
///   azul de Descargar en lugar de añadir un cuarto color nuevo.
/// * Los neutros oscuros (fondo, superficies y contenedores) son tonos
///   ligeramente violáceos en lugar de gris plano, lo que da profundidad sin
///   añadir más colores: fondo < superficie < contenedor < contenedor alto.
/// * Los acentos se usan solo en acentos (botones, selección, iconos), nunca en
///   superficies grandes, para que la interfaz no quede saturada.
library;

import 'package:flutter/material.dart';

/// Colores base de la paleta. Están centralizados aquí para poder ajustar el
/// tono de toda la aplicación desde un único sitio.
abstract final class AppColors {
  /// Fondo de la aplicación (el tono más oscuro).
  static const background = Color(0xFF0A0C18);

  /// Superficie del AppBar y del contenido principal.
  static const surface = Color(0xFF11152A);

  /// Contenedores de nivel medio (tarjetas de playlist).
  static const surfaceContainer = Color(0xFF181D38);

  /// Contenedor más alto (barra de reproducción, portadas de playlist). En la
  /// aplicación no coinciden a la vez en pantalla, así que comparten rol.
  static const surfaceContainerHighest = Color(0xFF232A4D);

  /// Acento principal: morado (botones y elementos destacados).
  static const primary = Color(0xFF8B7CFF);

  /// Acento secundario: azul.
  static const secondary = Color(0xFF5FA8E8);

  /// Acento terciario: violeta.
  static const tertiary = Color(0xFFC08BFF);

  /// Contenedores de los tres acentos, en la misma gama pero apagados.
  static const primaryContainer = Color(0xFF2E2660);
  static const secondaryContainer = Color(0xFF16324F);
  static const tertiaryContainer = Color(0xFF3B2258);

  /// Color sobre los contenedores de acento (texto e iconos).
  static const onAccentContainer = Color(0xFFEDEAFF);

  /// Contorno de campos y separadores.
  static const outline = Color(0xFF4A5178);

  /// Color de error, ligeramente desaturado para no romper la paleta.
  static const error = Color(0xFFFF8A9B);
}

/// Acento asociado a cada área de la navegación inferior.
///
/// El índice coincide con el destino de la barra de navegación (0 Playlists,
/// 1 Descargar, 2 Recomendaciones, 3 Visor de YouTube).
const List<Color> appSectionAccents = <Color>[
  AppColors.primary,
  AppColors.secondary,
  AppColors.tertiary,
  AppColors.secondary,
];

/// Superficie seleccionada de cada área de la navegación inferior.
const List<Color> appSectionSelectionColors = <Color>[
  AppColors.primaryContainer,
  AppColors.secondaryContainer,
  AppColors.tertiaryContainer,
  AppColors.secondaryContainer,
];

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onAccentContainer,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onAccentContainer,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onAccentContainer,
    surface: AppColors.surface,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surfaceContainer,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHighest,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outline: AppColors.outline,
    error: AppColors.error,
  );
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      // Sin elevación: la separación la da el cambio de tono entre el AppBar y
      // el fondo, no una sombra.
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.onAccentContainer),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: AppColors.onAccentContainer),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      thumbColor: AppColors.primary,
      inactiveTrackColor: AppColors.outline,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1),
  );
}
