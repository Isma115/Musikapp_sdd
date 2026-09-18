import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdd_music_simple/models/app_models.dart';
import 'package:sdd_music_simple/services/audio_player_service.dart';
import 'package:sdd_music_simple/services/local_storage_service.dart';
import 'package:sdd_music_simple/services/youtube_audio_service.dart';
import 'package:sdd_music_simple/theme/app_theme.dart';
import 'package:sdd_music_simple/views/music_shell.dart';
import 'package:sdd_music_simple/widgets/playback_bar.dart';

/// Almacenamiento en memoria: la prueba no toca disco ni canales de plataforma.
class _InMemoryStorage extends LocalStorageService {
  _InMemoryStorage(this._state);

  final StoredState _state;

  @override
  Future<StoredState> load() async => _state;

  @override
  Future<void> save(StoredState state) async {}
}

/// Reproductor falso: publica la cola que pide la vista sin abrir ficheros ni
/// canales nativos, para poder comprobar la interfaz de reproducción.
class _FakeAudioPlayerService extends AudioPlayerService {
  final _queueController = StreamController<PlaybackQueueState?>.broadcast();
  final streamedUris = <Uri>[];
  PlaybackQueueState? _queue;

  @override
  Future<void> dispose() => _queueController.close();

  @override
  PlaybackQueueState? get currentQueue => _queue;

  @override
  Stream<PlaybackQueueState?> get queueStream => _queueController.stream;

  @override
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      return;
    }
    _queue = PlaybackQueueState(
      queue: List<AudioTrack>.unmodifiable(tracks),
      index: startIndex.clamp(0, tracks.length - 1),
    );
    _queueController.add(_queue);
  }

  @override
  Future<void> playStream(Uri uri, {required String name}) async {
    streamedUris.add(uri);
    _queue = PlaybackQueueState(
      queue: <AudioTrack>[AudioTrack(path: uri.toString(), name: name)],
      index: 0,
    );
    _queueController.add(_queue);
  }

  @override
  Future<void> playNext() async {
    final queue = _queue;
    if (queue == null || !queue.hasNext) {
      return;
    }
    _queue = PlaybackQueueState(queue: queue.queue, index: queue.index + 1);
    _queueController.add(_queue);
  }

  @override
  Future<void> playPrevious() async {
    final queue = _queue;
    if (queue == null || !queue.hasPrevious) {
      return;
    }
    _queue = PlaybackQueueState(queue: queue.queue, index: queue.index - 1);
    _queueController.add(_queue);
  }

  @override
  Future<void> stop() async {
    _queue = null;
    _queueController.add(null);
  }
}

class _StreamingYouTubeService extends YouTubeAudioService {
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
  Future<Uri> getAudioStreamUri(YouTubeVideo video) async =>
      Uri.parse('https://stream.example.test/audio.mp4?video=${video.id}');
}

void main() {
  /// Spec "Fix: Sección de reproducción": al reproducir una canción, el cuadro
  /// de reproducción con los controles debe aparecer en ese mismo momento, sin
  /// tener que volver antes a la vista de las playlists.
  testWidgets('la sección de reproducción aparece al reproducir una canción', (
    tester,
  ) async {
    const track = AudioTrack(path: '/music/tema.mp3', name: 'Tema de prueba');
    final player = _FakeAudioPlayerService();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MusicShell(
          storage: _InMemoryStorage(
            const StoredState(
              playlists: <Playlist>[
                Playlist(name: 'Mi playlist', tracks: <AudioTrack>[track]),
              ],
            ),
          ),
          player: player,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Todavía no hay nada reproduciéndose: no hay cuadro de reproducción con
    // canción en curso.
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byTooltip('Expandir reproducción'), findsNothing);

    await tester.tap(find.text('Mi playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Añadir canción'), findsOneWidget);

    await tester.tap(find.byTooltip('Reproducir canción'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Sin volver atrás, la sección de reproducción ya está visible con el
    // título de la canción en curso y sus controles.
    expect(find.text('Tema de prueba'), findsWidgets);
    expect(find.text('1 de 1'), findsOneWidget);
    expect(find.byTooltip('Expandir reproducción'), findsOneWidget);
    expect(find.byTooltip('Canción anterior'), findsOneWidget);
    expect(find.byTooltip('Siguiente canción'), findsOneWidget);
    expect(find.byTooltip('Cerrar reproducción'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar reproducción'));
    await tester.pump();
    expect(find.text('1 de 1'), findsNothing);
    expect(find.byTooltip('Cerrar reproducción'), findsNothing);
  });

  /// El detalle ya no es una ruta propia, así que el gesto/botón atrás del
  /// sistema debe devolver a la lista de playlists en vez de cerrar la app.
  testWidgets('el gesto atrás del sistema vuelve del detalle a las playlists', (
    tester,
  ) async {
    final player = _FakeAudioPlayerService();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MusicShell(
          storage: _InMemoryStorage(
            const StoredState(
              playlists: <Playlist>[
                Playlist(
                  name: 'Mi playlist',
                  tracks: <AudioTrack>[
                    AudioTrack(path: '/music/tema.mp3', name: 'Tema'),
                  ],
                ),
              ],
            ),
          ),
          player: player,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Mi playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Añadir canción'), findsOneWidget);

    // Ruta de "atrás" que usa el sistema (botón o gesto).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Añadir canción'), findsNothing);
    expect(find.text('Añadir Playlist'), findsOneWidget);
  });

  /// La barra de reproducción debe seguir navegando dentro del detalle, que es
  /// donde el usuario está cuando empieza a sonar la canción.
  testWidgets('los controles funcionan mientras se ve el detalle', (
    tester,
  ) async {
    const first = AudioTrack(path: '/music/uno.mp3', name: 'Primera');
    const second = AudioTrack(path: '/music/dos.mp3', name: 'Segunda');
    final player = _FakeAudioPlayerService();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MusicShell(
          storage: _InMemoryStorage(
            const StoredState(
              playlists: <Playlist>[
                Playlist(
                  name: 'Mi playlist',
                  tracks: <AudioTrack>[first, second],
                ),
              ],
            ),
          ),
          player: player,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Mi playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reproducir canción').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Primera'), findsWidgets);
    expect(find.text('1 de 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Siguiente canción'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Segunda'), findsWidgets);
    expect(find.text('2 de 2'), findsOneWidget);
  });

  testWidgets('el visor reproduce el audio remoto sin descargarlo', (
    tester,
  ) async {
    final player = _FakeAudioPlayerService();
    final youtubeService = _StreamingYouTubeService();
    addTearDown(player.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MusicShell(
          storage: _InMemoryStorage(const StoredState()),
          youtubeService: youtubeService,
          player: player,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Youtube'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'prueba');
    await tester.tap(find.byTooltip('Buscar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vídeo de prueba'), findsOneWidget);
    await tester.tap(find.byTooltip('Reproducir audio de YouTube'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(player.streamedUris, hasLength(1));
    expect(player.streamedUris.single.scheme, 'https');
    expect(player.currentQueue?.current.name, 'Vídeo de prueba');
    expect(find.byTooltip('Cerrar reproducción'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar reproducción'));
    await tester.pump();
    expect(player.currentQueue, isNull);
    expect(find.text('1 de 1'), findsNothing);
  });
}
