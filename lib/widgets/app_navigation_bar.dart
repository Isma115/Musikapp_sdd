import 'package:flutter/material.dart';

/// Barra inferior cuya selección ocupa todo el destino elegido.
///
/// `NavigationBar` limita su indicador Material 3 a 64x32 píxeles. Se
/// conserva el componente y sus destinos para mantener la navegación y la
/// accesibilidad, pero se coloca detrás una superficie rectangular del ancho
/// completo del destino seleccionado.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.selectionColor,
    required this.destinations,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color selectionColor;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final destinationWidth =
            constraints.maxWidth / destinations.length.toDouble();
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned(
                left: destinationWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: destinationWidth,
                child: ColoredBox(color: selectionColor),
              ),
              NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                destinations: destinations,
              ),
            ],
          ),
        );
      },
    );
  }
}
