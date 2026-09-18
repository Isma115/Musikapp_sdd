import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/app_models.dart';

/// Estado de la cola de reproducción actual.
class PlaybackQueueState {
  const PlaybackQueueState({required this.queue, required this.index});

  final List<AudioTrack> queue;
  final int index;

  AudioTrack get current => queue[index];
  bool get hasPrevious => index > 0;
  bool get hasNext => index + 1 < queue.length;
}

/// Reproductor local de canciones (archivos del dispositivo).
///
/// La cola la fija la vista que inicia la reproducción (playlist o
/// recomendaciones). No persiste nada: respeta el almacenamiento local
/// existente sin añadir tablas ni recursos.
class AudioPlayerService {
  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final _queueController = StreamController<PlaybackQueueState?>.broadcast();
  PlaybackQueueState? _queueState;
  bool _disposed = false;
  int _playbackRequest = 0;

  AudioPlayer get player => _player;

  PlaybackQueueState? get currentQueue => _queueState;

  Stream<PlaybackQueueState?> get queueStream => _queueController.stream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<Duration> get positionStream => _player.positionStream;

  /// Reproduce [tracks] desde [startIndex] y la deja como cola activa para
  /// anterior/siguiente.
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty || _disposed) {
      return;
    }
    final request = ++_playbackRequest;
    final index = startIndex.clamp(0, tracks.length - 1);
    _queueState = PlaybackQueueState(
      queue: List<AudioTrack>.unmodifiable(tracks),
      index: index,
    );
    _queueController.add(_queueState);
    await _playCurrent(request);
  }

  /// Reproduce una pista remota sin incorporarla al almacenamiento local.
  ///
  /// La cola se mantiene con una sola entrada para que la barra de
  /// reproducción reutilice sus controles, pero [uri] nunca se guarda como
  /// una canción descargada.
  Future<void> playStream(Uri uri, {required String name}) async {
    if (_disposed) {
      return;
    }
    final request = ++_playbackRequest;
    final previousQueue = _queueState;
    _queueState = PlaybackQueueState(
      queue: <AudioTrack>[AudioTrack(path: uri.toString(), name: name)],
      index: 0,
    );
    _queueController.add(_queueState);
    try {
      await _playCurrent(request);
    } on Object {
      if (request != _playbackRequest || _disposed) {
        return;
      }
      _queueState = previousQueue;
      _queueController.add(previousQueue);
      rethrow;
    }
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      // Si no hay fuente cargada pero sí cola, (re)carga la actual.
      if (_player.audioSource == null && _queueState != null) {
        await _playCurrent(++_playbackRequest);
      } else {
        await _player.play();
      }
    }
  }

  /// Detiene la reproducción y elimina la cola visible en la interfaz.
  ///
  /// `AudioPlayer.stop` conserva la fuente cargada para poder reanudarla,
  /// pero cerrar la ventana de reproducción requiere que el estado de cola
  /// compartido también vuelva a ser nulo.
  Future<void> stop() async {
    if (_disposed) {
      return;
    }
    final request = ++_playbackRequest;
    await _player.stop();
    if (request != _playbackRequest || _disposed) {
      return;
    }
    _queueState = null;
    _queueController.add(null);
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> playNext() async {
    final state = _queueState;
    if (state == null || !state.hasNext || _disposed) {
      return;
    }
    final request = ++_playbackRequest;
    _queueState = PlaybackQueueState(
      queue: state.queue,
      index: state.index + 1,
    );
    _queueController.add(_queueState);
    await _playCurrent(request);
  }

  Future<void> playPrevious() async {
    final state = _queueState;
    if (state == null || !state.hasPrevious || _disposed) {
      return;
    }
    final request = ++_playbackRequest;
    _queueState = PlaybackQueueState(
      queue: state.queue,
      index: state.index - 1,
    );
    _queueController.add(_queueState);
    await _playCurrent(request);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> _playCurrent(int request) async {
    if (_disposed || request != _playbackRequest) {
      return;
    }
    final track = _queueState?.current;
    if (track == null) {
      return;
    }
    try {
      final remoteUri = _remoteUri(track.path);
      final sourceUri = remoteUri ?? Uri.file(track.path);
      if (remoteUri == null && !await File(track.path).exists()) {
        throw StateError('El archivo ya no está disponible en el dispositivo.');
      }
      await _player.setAudioSource(
        AudioSource.uri(
          sourceUri,
          tag: MediaItem(
            id: track.path,
            album: remoteUri == null ? 'SDD Music' : 'YouTube',
            title: track.name,
          ),
        ),
      );
      // Loading a source is asynchronous. A stop, next/previous action, or a
      // new selection may have invalidated this operation while it was
      // waiting. Never let that stale operation start playback again after
      // the user has closed or replaced the queue.
      if (_disposed ||
          request != _playbackRequest ||
          _queueState?.current.path != track.path) {
        return;
      }
      await _player.play();
    } on StateError {
      if (_disposed || request != _playbackRequest) {
        return;
      }
      rethrow;
    } on Object {
      if (_disposed || request != _playbackRequest) {
        return;
      }
      throw StateError('No se pudo reproducir la canción seleccionada.');
    }
  }

  Uri? _remoteUri(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri;
  }

  Future<void> dispose() async {
    _disposed = true;
    _playbackRequest++;
    await _queueController.close();
    await _player.dispose();
  }
}
