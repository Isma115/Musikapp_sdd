import 'package:flutter/material.dart';

/// Decoración de fondo de una vista.
///
/// Spec "Iconos atractivos": en el fondo de las vistas, de forma sutil,
/// aparecen iconos o símbolos en grande para decorar visualmente la aplicación.
///
/// Cómo se mantiene sutil y dentro de la paleta:
/// * Los iconos se pintan con el color de acento del área, a una opacidad muy
///   baja (~5%), sobre el fondo oscuro ya existente: nunca compiten con el
///   contenido ni introducen colores nuevos.
/// * Se colocan en los márgenes (arriba a la izquierda, arriba a la derecha y
///   abajo a la derecha) para que queden detrás de zonas sin información.
/// * La capa decorativa está por debajo del contenido y no intercepta toques
///   (los iconos solo envuelven la interfaz, no la sustituyen ni la desplazan).
class BackgroundDecor extends StatelessWidget {
  const BackgroundDecor({
    required this.icons,
    required this.accent,
    required this.child,
    this.iconSize = 150,
    super.key,
  });

  /// Símbolos grandes que decoran el fondo, de arriba abajo del lienzo.
  final List<IconData> icons;

  /// Color de acento del área; se usa siempre a baja opacidad.
  final Color accent;

  final Widget child;
  final double iconSize;

  static const List<Alignment> _placements = <Alignment>[
    Alignment(-1.15, -1.05),
    Alignment(1.15, -0.35),
    Alignment(-1.05, 0.95),
    Alignment(0.95, 1.15),
  ];

  static const List<double> _opacities = <double>[0.05, 0.04, 0.045, 0.035];

  @override
  Widget build(BuildContext context) {
    if (icons.isEmpty) {
      return child;
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          // El contenedor conserva el tono de fondo de la aplicación; la
          // decoración se apoya encima, nunca cambia la superficie base.
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              children: [
                for (var index = 0; index < icons.length; index++)
                  Align(
                    alignment: _placements[index % _placements.length],
                    child: Opacity(
                      opacity: _opacities[index % _opacities.length],
                      child: Icon(icons[index], size: iconSize, color: accent),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Tinte del acento del área, también muy suave, para que el fondo
        // tenga un foco de color sin cargar la vista.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.2,
                colors: <Color>[
                  accent.withValues(alpha: 0.06),
                  colorScheme.surface.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
