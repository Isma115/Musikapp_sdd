import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdd_music_simple/main.dart';

void main() {
  testWidgets('muestra playlists y las cuatro áreas de navegación', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Añadir Playlist'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Descargar'), findsOneWidget);
    expect(find.text('Recomendar'), findsOneWidget);
    expect(find.text('Youtube'), findsOneWidget);
    expect(find.text('Todavía no hay playlists creadas.'), findsOneWidget);
  });
}
