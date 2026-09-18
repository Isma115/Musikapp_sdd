import 'package:flutter_test/flutter_test.dart';

import 'package:sdd_music_simple/models/app_models.dart';
import 'package:sdd_music_simple/services/recommendation_service.dart';

void main() {
  test('ordena las canciones por su puntuación local', () {
    const playlistTrack = AudioTrack(path: '/music/favorite.mp3', name: 'Favorita');
    const downloadedTrack = AudioTrack(path: '/downloads/new.mp3', name: 'Nueva');
    const service = RecommendationService();

    final recommendations = service.recommend(
      playlists: const <Playlist>[
        Playlist(name: 'Mi playlist', tracks: <AudioTrack>[playlistTrack]),
      ],
      libraryTracks: const <AudioTrack>[playlistTrack, downloadedTrack],
      downloads: const <AudioTrack>[downloadedTrack],
    );

    expect(recommendations.map((item) => item.track.name), <String>[
      'Favorita',
      'Nueva',
    ]);
    expect(recommendations.map((item) => item.score), <int>[2, 1]);
  });
}
