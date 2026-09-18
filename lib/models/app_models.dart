import 'package:path/path.dart' as p;

import '../utils/playlist_colors.dart';

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
  const Playlist({
    required this.name,
    this.tracks = const <AudioTrack>[],
    this.iconColorIndex,
  });

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

    return Playlist(
      name: name.trim(),
      tracks: tracks,
      // Spec "Icono de playlist con color": el color se guarda como índice de
      // la paleta de la aplicación. Un índice desconocido (fichero editado a
      // mano o paleta recortada) se descarta y la playlist queda sin color.
      iconColorIndex: PlaylistColors.normalizeIndex(
        json['iconColorIndex'] is int ? json['iconColorIndex'] as int : null,
      ),
    );
  }

  final String name;
  final List<AudioTrack> tracks;

  /// Color del icono de la playlist como índice de la paleta de la aplicación
  /// (`appPlaylistIconColors`). `null` mientras el usuario no le haya dado
  /// color.
  final int? iconColorIndex;

  Playlist copyWithTracks(List<AudioTrack> updatedTracks) => Playlist(
    name: name,
    tracks: List<AudioTrack>.unmodifiable(updatedTracks),
    iconColorIndex: iconColorIndex,
  );

  /// Devuelve la playlist con otro color de icono.
  Playlist copyWithIconColor(int? updatedIconColorIndex) => Playlist(
    name: name,
    tracks: tracks,
    iconColorIndex: PlaylistColors.normalizeIndex(updatedIconColorIndex),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'tracks': tracks.map((track) => track.toJson()).toList(),
    if (iconColorIndex != null) 'iconColorIndex': iconColorIndex,
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
