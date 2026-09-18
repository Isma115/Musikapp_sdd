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
    final index = startIndex.clamp(0, tracks.length - 1);
    _queueState = PlaybackQueueState(
      queue: List<AudioTrack>.unmodifiable(tracks),
      index: index,
    );
    _queueController.add(_queueState);
    await _playCurrent();
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      // Si no hay fuente cargada pero sí cola, (re)carga la actual.
      if (_player.audioSource == null && _queueState != null) {
        await _playCurrent();
      } else {
        await _player.play();
      }
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.play();

  Future<void> playNext() async {
    final state = _queueState;
    if (state == null || !state.hasNext || _disposed) {
      return;
    }
    _queueState = PlaybackQueueState(
      queue: state.queue,
      index: state.index + 1,
    );
    _queueController.add(_queueState);
    await _playCurrent();
  }

  Future<void> playPrevious() async {
    final state = _queueState;
    if (state == null || !state.hasPrevious || _disposed) {
      return;
    }
    _queueState = PlaybackQueueState(
      queue: state.queue,
      index: state.index - 1,
    );
    _queueController.add(_queueState);
    await _playCurrent();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> _playCurrent() async {
    final track = _queueState?.current;
    if (track == null) {
      return;
    }
    try {
      if (!await File(track.path).exists()) {
        throw StateError('El archivo ya no está disponible en el dispositivo.');
      }
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.file(track.path),
          tag: MediaItem(id: track.path, album: 'SDD Music', title: track.name),
        ),
      );
      await _player.play();
    } on StateError {
      rethrow;
    } on Object {
      throw StateError('No se pudo reproducir la canción seleccionada.');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _queueController.close();
    await _player.dispose();
  }
}
