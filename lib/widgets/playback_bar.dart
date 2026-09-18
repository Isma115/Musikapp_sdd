import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio_player_service.dart';
import '../utils/duration_format.dart';

/// Barra de reproducción persistente con modos contraído/expandido.
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento: permite
/// usar el resto de vistas mientras suena la canción.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    required this.player,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.onToggle,
    required this.onNext,
    required this.onPrevious,
    super.key,
  });

  final AudioPlayerService player;
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final Future<void> Function() onToggle;
  final Future<void> Function() onNext;
  final Future<void> Function() onPrevious;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackQueueState?>(
      initialData: player.currentQueue,
      stream: player.queueStream,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? player.currentQueue;
        if (queue == null) {
          return const SizedBox.shrink();
        }
        if (isExpanded) {
          return _ExpandedPlayer(
            player: player,
            queue: queue,
            onCollapse: () => onExpandChanged(false),
            onToggle: onToggle,
            onNext: onNext,
            onPrevious: onPrevious,
          );
        }
        return _CollapsedPlayer(
          player: player,
          queue: queue,
          onExpand: () => onExpandChanged(true),
          onToggle: onToggle,
          onNext: onNext,
          onPrevious: onPrevious,
        );
      },
    );
  }
}

class _CollapsedPlayer extends StatelessWidget {
  const _CollapsedPlayer({
    required this.player,
    required this.queue,
    required this.onExpand,
    required this.onToggle,
    required this.onNext,
    required this.onPrevious,
  });

  final AudioPlayerService player;
  final PlaybackQueueState queue;
  final VoidCallback onExpand;
  final Future<void> Function() onToggle;
  final Future<void> Function() onNext;
  final Future<void> Function() onPrevious;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            IconButton(
              onPressed: onExpand,
              tooltip: 'Expandir reproducción',
              icon: const Icon(Icons.expand_less),
            ),
            Expanded(
              child: InkWell(
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        queue.current.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${queue.index + 1} de ${queue.queue.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: queue.hasPrevious ? onPrevious : null,
              tooltip: 'Canción anterior',
              icon: const Icon(Icons.skip_previous),
            ),
            PlaybackToggleButton(player: player, onToggle: onToggle),
            IconButton(
              onPressed: queue.hasNext ? onNext : null,
              tooltip: 'Siguiente canción',
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedPlayer extends StatelessWidget {
  const _ExpandedPlayer({
    required this.player,
    required this.queue,
    required this.onCollapse,
    required this.onToggle,
    required this.onNext,
    required this.onPrevious,
  });

  final AudioPlayerService player;
  final PlaybackQueueState queue;
  final VoidCallback onCollapse;
  final Future<void> Function() onToggle;
  final Future<void> Function() onNext;
  final Future<void> Function() onPrevious;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    queue.current.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: onCollapse,
                  tooltip: 'Contraer reproducción',
                  icon: const Icon(Icons.expand_more),
                ),
              ],
            ),
            Text(
              '${queue.index + 1} de ${queue.queue.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            PlaybackProgress(player: player),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: queue.hasPrevious ? onPrevious : null,
                  tooltip: 'Canción anterior',
                  icon: const Icon(Icons.skip_previous),
                ),
                PlaybackToggleButton(
                  player: player,
                  onToggle: onToggle,
                  size: 40,
                ),
                IconButton(
                  onPressed: queue.hasNext ? onNext : null,
                  tooltip: 'Siguiente canción',
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlaybackToggleButton extends StatelessWidget {
  const PlaybackToggleButton({
    required this.player,
    required this.onToggle,
    this.size = 24,
    super.key,
  });

  final AudioPlayerService player;
  final Future<void> Function() onToggle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return IconButton(
          onPressed: onToggle,
          tooltip: playing ? 'Pausar' : 'Reproducir',
          icon: Icon(
            playing ? Icons.pause : Icons.play_arrow,
            size: size,
          ),
        );
      },
    );
  }
}

class PlaybackProgress extends StatelessWidget {
  const PlaybackProgress({required this.player, super.key});

  final AudioPlayerService player;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnapshot) {
        final total = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          initialData: Duration.zero,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            final value = position.inMilliseconds
                .clamp(0, total.inMilliseconds)
                .toDouble();
            return Row(
              children: [
                Text(formatPlaybackDuration(position)),
                Expanded(
                  child: Slider(
                    value: max <= 0 ? 0 : value,
                    max: max <= 0 ? 1 : max,
                    onChanged: max <= 0
                        ? null
                        : (newValue) => player.seek(
                            Duration(milliseconds: newValue.round()),
                          ),
                  ),
                ),
                Text(formatPlaybackDuration(total)),
              ],
            );
          },
        );
      },
    );
  }
}
