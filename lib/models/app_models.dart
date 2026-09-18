import 'package:path/path.dart' as p;

class AudioTrack {
  const AudioTrack({required this.path, required this.name});

  factory AudioTrack.fromPath(String path, {String? name}) {
    final fallbackName = p.basenameWithoutExtension(path);
    return AudioTrack(
      path: path,
      name: name == null || name.trim().isEmpty ? fallbackName : name.trim(),
    );
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    final path = json['path'];
    if (path is! String || path.trim().isEmpty) {
      throw const FormatException('La canción no contiene una ruta válida.');
    }

    final name = json['name'];
    return AudioTrack.fromPath(
      path,
      name: name is String && name.trim().isNotEmpty ? name : null,
    );
  }

  final String path;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'name': name,
  };
}

class Playlist {
  const Playlist({required this.name, this.tracks = const <AudioTrack>[]});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('La playlist no contiene un nombre válido.');
    }

    final tracksJson = json['tracks'];
    final tracks = <AudioTrack>[];
    if (tracksJson is List) {
      for (final trackJson in tracksJson) {
        if (trackJson is! Map) {
          continue;
        }
        try {
          tracks.add(AudioTrack.fromJson(Map<String, dynamic>.from(trackJson)));
        } on FormatException {
          // Ignora únicamente entradas dañadas y conserva el resto de la lista.
        }
      }
    }

    return Playlist(name: name.trim(), tracks: tracks);
  }

  final String name;
  final List<AudioTrack> tracks;

  Playlist copyWithTracks(List<AudioTrack> updatedTracks) => Playlist(
    name: name,
    tracks: List<AudioTrack>.unmodifiable(updatedTracks),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'tracks': tracks.map((track) => track.toJson()).toList(),
  };
}

class StoredState {
  const StoredState({
    this.playlists = const <Playlist>[],
    this.downloads = const <AudioTrack>[],
  });

  factory StoredState.fromJson(Map<String, dynamic> json) {
    final playlists = <Playlist>[];
    final playlistsJson = json['playlists'];
    if (playlistsJson is List) {
      for (final playlistJson in playlistsJson) {
        if (playlistJson is! Map) {
          continue;
        }
        try {
          playlists.add(
            Playlist.fromJson(Map<String, dynamic>.from(playlistJson)),
          );
        } on FormatException {
          // Ignora playlists dañadas sin perder las demás.
        }
      }
    }

    final downloads = <AudioTrack>[];
    final downloadsJson = json['downloads'];
    if (downloadsJson is List) {
      for (final downloadJson in downloadsJson) {
        if (downloadJson is! Map) {
          continue;
        }
        try {
          downloads.add(
            AudioTrack.fromJson(Map<String, dynamic>.from(downloadJson)),
          );
        } on FormatException {
          // Ignora descargas dañadas sin perder las demás.
        }
      }
    }

    return StoredState(playlists: playlists, downloads: downloads);
  }

  final List<Playlist> playlists;
  final List<AudioTrack> downloads;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'playlists': playlists.map((playlist) => playlist.toJson()).toList(),
    'downloads': downloads.map((download) => download.toJson()).toList(),
  };
}
