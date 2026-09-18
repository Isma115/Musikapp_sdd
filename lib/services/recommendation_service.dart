import '../models/app_models.dart';

class RecommendedTrack {
  const RecommendedTrack({required this.track, required this.score});

  final AudioTrack track;
  final int score;
}

class RecommendationService {
  const RecommendationService();

  List<RecommendedTrack> recommend({
    required List<Playlist> playlists,
    required List<AudioTrack> libraryTracks,
    required List<AudioTrack> downloads,
  }) {
    final tracksByPath = <String, AudioTrack>{};
    final scoresByPath = <String, int>{};

    void addCandidate(AudioTrack track) {
      tracksByPath[track.path] = track;
      scoresByPath.putIfAbsent(track.path, () => 0);
    }

    for (final track in libraryTracks) {
      addCandidate(track);
    }
    for (final track in downloads) {
      addCandidate(track);
      scoresByPath[track.path] = (scoresByPath[track.path] ?? 0) + 1;
    }
    for (final playlist in playlists) {
      for (final track in playlist.tracks) {
        addCandidate(track);
        // La pertenencia a una playlist representa la preferencia local que
        // la especificación deja disponible al no definir un reproductor ni
        // un historial de escucha persistido.
        scoresByPath[track.path] = (scoresByPath[track.path] ?? 0) + 2;
      }
    }

    final recommendations = scoresByPath.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => RecommendedTrack(
            track: tracksByPath[entry.key]!,
            score: entry.value,
          ),
        )
        .toList();
    recommendations.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      if (scoreOrder != 0) {
        return scoreOrder;
      }
      return left.track.name.toLowerCase().compareTo(
        right.track.name.toLowerCase(),
      );
    });
    return recommendations;
  }
}
