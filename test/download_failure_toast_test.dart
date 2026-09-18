import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdd_music_simple/services/youtube_audio_service.dart';
import 'package:sdd_music_simple/theme/app_theme.dart';
import 'package:sdd_music_simple/views/music_shell.dart';

/// Servicio de YouTube que siempre falla al descargar, para poder comprobar el
/// aviso de error sin depender de la red ni de FFmpeg.
class _FailingYouTubeService extends YouTubeAudioService {
  @override
  Future<List<YouTubeVideo>> search(String query) async => const <YouTubeVideo>[
    YouTubeVideo(
      id: 'video-de-prueba',
      title: 'Vídeo de prueba',
      author: 'Autor',
      duration: Duration(seconds: 60),
      thumbnailUrl: '',
    ),
  ];

  @override
  Future<File> downloadAsMp3(
    YouTubeVideo video, {
    DownloadMethod method = DownloadMethod.automatic,
    void Function(double progress)? onProgress,
  }) async {
    throw StateError('La descarga ha fallado en la prueba.');
  }
}

void main() {
  testWidgets('el aviso de error de descarga se cierra solo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MusicShell(youtubeService: _FailingYouTubeService()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'prueba');
    await tester.pump();
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vídeo de prueba'), findsOneWidget);

    await tester.tap(find.byTooltip('Descargar audio'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // El aviso conserva las dos opciones exigidas por el spec
    // "Mensaje de Error en descarga".
    expect(find.text('Mostrar'), findsOneWidget);
    expect(find.text('Opciones'), findsOneWidget);

    // Spec "Fix: Toasts demasiado largos": el aviso se cierra solo pasado su
    // tiempo de vida, sin que el usuario tenga que descartarlo.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Mostrar'), findsNothing);
    expect(find.text('Opciones'), findsNothing);
  });
}
