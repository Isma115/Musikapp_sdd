import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/background_decoration.dart';
import '../widgets/empty_state.dart';

/// Vista de recomendaciones (lista con puntuación).
/// Extraída de `main.dart` sin cambios visuales ni de comportamiento: cada
/// canción se reproduce con el botón o pulsando la fila.
class RecommendationsView extends StatelessWidget {
  const RecommendationsView({
    required this.queue,
    required this.scores,
    required this.onPlayAt,
    super.key,
  });

  /// Símbolos grandes del fondo (spec "Iconos atractivos").
  static const _backgroundIcons = <IconData>[
    Icons.auto_awesome,
    Icons.equalizer,
    Icons.favorite,
  ];

  final List<AudioTrack> queue;
  final List<int> scores;
  final ValueChanged<int> onPlayAt;

  @override
  Widget build(BuildContext context) {
    return BackgroundDecor(
      icons: _backgroundIcons,
      accent: appSectionAccents[2],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (queue.isEmpty) {
      return const EmptyState(
        icon: Icons.auto_awesome,
        message: 'Añade o descarga canciones para ver recomendaciones.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: queue.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: IconButton(
            onPressed: () => onPlayAt(index),
            tooltip: 'Reproducir canción',
            icon: const Icon(Icons.play_arrow),
          ),
          title: Text(queue[index].name),
          subtitle: Text('Puntuación: ${scores[index]}'),
          onTap: () => onPlayAt(index),
        );
      },
    );
  }
}
