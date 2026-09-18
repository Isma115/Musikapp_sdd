import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_models.dart';
import '../services/audio_player_service.dart';
import '../services/local_storage_service.dart';
import '../services/music_scanner.dart';
import '../services/recommendation_service.dart';
import '../services/youtube_audio_service.dart';
import '../widgets/playback_bar.dart';
import 'playlist_detail_page.dart';
import 'playlists_view.dart';
import 'recommendations_view.dart';
import 'youtube_search_view.dart';

/// Shell con la navegación inferior y el estado compartido.
/// Orquesta servicios (funcionamiento) y vistas; el render de cada vista vive
/// en `views/` y los componentes reutilizables en `widgets/`.
class MusicShell extends StatefulWidget {
  const MusicShell({
    super.key,
    this.storage,
    this.scanner,
    this.youtubeService,
    this.player,
  });

  final LocalStorageService? storage;
  final MusicScanner? scanner;
  final YouTubeAudioService? youtubeService;
  final AudioPlayerService? player;

  @override
  State<MusicShell> createState() => MusicShellState();
}

class MusicShellState extends State<MusicShell> with WidgetsBindingObserver {
  static const _snackBarDuration = Duration(seconds: 3);

  static const viewTitles = <String>[
    'Playlists',
    'Descargar',
    'Recomendaciones',
    'Visor de YouTube',
  ];

  late final LocalStorageService _storage;
  late final MusicScanner _scanner;
  late final RecommendationService _recommendationService;
  late final YouTubeAudioService _youtubeService;
  late final AudioPlayerService _player;

  final _downloadSearchController = TextEditingController();
  final _viewerSearchController = TextEditingController();
  final _downloadingVideoIds = <String>{};
  final _downloadProgress = <String, double>{};

  List<Playlist> _playlists = const <Playlist>[];
  List<AudioTrack> _libraryTracks = const <AudioTrack>[];
  List<AudioTrack> _downloads = const <AudioTrack>[];
  List<YouTubeVideo> _downloadResults = const <YouTubeVideo>[];
  List<YouTubeVideo> _viewerResults = const <YouTubeVideo>[];

  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isDownloadingSearch = false;
  bool _isViewerSearching = false;
  bool _isPlayerExpanded = false;
  String? _downloadError;
  String? _viewerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _storage = widget.storage ?? LocalStorageService();
    _scanner = widget.scanner ?? MusicScanner();
    _recommendationService = const RecommendationService();
    _youtubeService = widget.youtubeService ?? YouTubeAudioService();
    _player = widget.player ?? AudioPlayerService();
    unawaited(_loadApplication());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _downloadSearchController.dispose();
    _viewerSearchController.dispose();
    if (widget.youtubeService == null) {
      _youtubeService.dispose();
    }
    if (widget.player == null) {
      unawaited(_player.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Escaneo manual (spec "Recarga de canciones"): volver a la app no
    // reescanea; solo el botón de recargar llama a [_rescanMusic].
    // Reproducción en segundo plano: ningún estado pausa ni detiene el audio.
  }

  Future<void> _loadApplication() async {
    var storedState = const StoredState();
    try {
      storedState = await _storage.load();
    } on Object {
      // La interfaz queda disponible aunque el almacenamiento todavía no esté
      // disponible en la plataforma actual.
    }
    if (!mounted) {
      return;
    }
    // Escaneo manual: al entrar no se escanea; la biblioteca queda vacía
    // hasta que el usuario pulse el botón de recargar.
    setState(() {
      _playlists = storedState.playlists;
      _downloads = storedState.downloads;
      _libraryTracks = const <AudioTrack>[];
      _isLoading = false;
    });
  }

  Future<void> _rescanMusic() async {
    if (_isScanning) {
      return;
    }
    setState(() => _isScanning = true);
    final scannedTracks = await _scanner.scan();
    if (!mounted) {
      return;
    }
    setState(() {
      _libraryTracks = scannedTracks;
      _isScanning = false;
    });
    _showMessage('Escaneo completado: ${scannedTracks.length} canciones.');
  }

  Future<void> _persist() async {
    try {
      await _storage.save(
        StoredState(playlists: _playlists, downloads: _downloads),
      );
    } on Object {
      if (mounted) {
        _showMessage('No se pudieron guardar los cambios en el dispositivo.');
      }
    }
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null) {
      return;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _showMessage('Escribe un nombre para la playlist.');
      return;
    }
    if (_playlists.any(
      (playlist) => playlist.name.toLowerCase() == trimmedName.toLowerCase(),
    )) {
      _showMessage('Ya existe una playlist con ese nombre.');
      return;
    }

    setState(() {
      _playlists = <Playlist>[..._playlists, Playlist(name: trimmedName)];
    });
    await _persist();
  }

  Future<void> _openPlaylist(int playlistIndex) async {
    final playlist = _playlists[playlistIndex];
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailPage(
          playlist: playlist,
          availableTracks: _libraryTracks,
          onTracksChanged: (tracks) =>
              _replacePlaylistTracks(playlistIndex, tracks),
          onPlayQueue: (tracks, startIndex) =>
              _playTracks(tracks, startIndex: startIndex),
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _replacePlaylistTracks(int playlistIndex, List<AudioTrack> tracks) {
    if (playlistIndex < 0 || playlistIndex >= _playlists.length) {
      return;
    }
    setState(() {
      _playlists[playlistIndex] = _playlists[playlistIndex].copyWithTracks(
        tracks,
      );
    });
    unawaited(_persist());
  }

  Future<void> _playTracks(List<AudioTrack> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) {
      return;
    }
    final index = startIndex.clamp(0, queue.length - 1);
    try {
      await _player.playQueue(queue, startIndex: index);
    } on Object catch (error) {
      if (mounted) {
        _showMessage(
          error is StateError
              ? error.message
              : 'No se pudo reproducir la canción seleccionada.',
        );
      }
      return;
    }
    if (mounted) {
      setState(() => _isPlayerExpanded = false);
    }
  }

  Future<void> _togglePlayback() async {
    try {
      await _player.toggle();
    } on Object {
      if (mounted) {
        _showMessage('No se pudo reproducir la canción seleccionada.');
      }
    }
  }

  Future<void> _playNextInQueue() async {
    try {
      await _player.playNext();
    } on Object {
      if (mounted) {
        _showMessage('No se pudo reproducir la siguiente canción.');
      }
    }
  }

  Future<void> _playPreviousInQueue() async {
    try {
      await _player.playPrevious();
    } on Object {
      if (mounted) {
        _showMessage('No se pudo reproducir la canción anterior.');
      }
    }
  }

  Future<void> _searchYouTube(YouTubeSection section) async {
    final controller = section == YouTubeSection.download
        ? _downloadSearchController
        : _viewerSearchController;
    final query = controller.text.trim();
    final isSearching = section == YouTubeSection.download
        ? _isDownloadingSearch
        : _isViewerSearching;
    if (query.isEmpty || isSearching) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      if (section == YouTubeSection.download) {
        _isDownloadingSearch = true;
        _downloadError = null;
        _downloadResults = const <YouTubeVideo>[];
      } else {
        _isViewerSearching = true;
        _viewerError = null;
        _viewerResults = const <YouTubeVideo>[];
      }
    });
    try {
      final results = await _youtubeService.search(query);
      if (!mounted) {
        return;
      }
      setState(() {
        if (section == YouTubeSection.download) {
          _downloadResults = results;
        } else {
          _viewerResults = results;
        }
      });
    } on Object {
      if (mounted) {
        setState(() {
          if (section == YouTubeSection.download) {
            _downloadError = 'No se pudo completar la búsqueda.';
          } else {
            _viewerError = 'No se pudo completar la búsqueda.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (section == YouTubeSection.download) {
            _isDownloadingSearch = false;
          } else {
            _isViewerSearching = false;
          }
        });
      }
    }
  }

  Future<void> _openYouTubeVideo(YouTubeVideo video) async {
    final opened = await launchUrl(
      video.watchUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('No se pudo abrir el vídeo en YouTube.');
    }
  }

  Future<void> _downloadVideo(
    YouTubeVideo video, {
    DownloadMethod method = DownloadMethod.automatic,
  }) async {
    if (_downloadingVideoIds.contains(video.id)) {
      return;
    }
    setState(() {
      _downloadingVideoIds.add(video.id);
      _downloadProgress.remove(video.id);
    });
    try {
      final file = await _youtubeService.downloadAsMp3(
        video,
        method: method,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          final clamped = progress.clamp(0.0, 1.0);
          final previous = _downloadProgress[video.id];
          if (previous == null ||
              (clamped - previous).abs() >= 0.01 ||
              clamped >= 1.0) {
            setState(() => _downloadProgress[video.id] = clamped);
          }
        },
      );
      final track = AudioTrack.fromPath(file.path, name: video.title);
      if (!mounted) {
        return;
      }
      if (!_downloads.any((download) => download.path == track.path)) {
        setState(() => _downloads = <AudioTrack>[..._downloads, track]);
        await _persist();
      }
      _showMessage('Audio descargado en Descargas.');
    } on Object catch (error) {
      if (mounted) {
        final detail = error is StateError ? error.message : null;
        _showDownloadFailure(video, detail, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingVideoIds.remove(video.id);
          _downloadProgress.remove(video.id);
        });
      }
    }
  }

  void _showDownloadFailure(
    YouTubeVideo video,
    String? detail,
    String fullError,
  ) {
    if (!mounted) {
      return;
    }
    final message = detail == null || detail.isEmpty
        ? 'No se pudo descargar el audio.'
        : detail;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(child: Text(message)),
              TextButton(
                onPressed: () => _showDownloadErrorDetails(fullError),
                child: const Text('Mostrar'),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Opciones',
            onPressed: () => _showDownloadOptions(video),
          ),
          duration: _snackBarDuration,
        ),
      );
  }

  Future<void> _showDownloadErrorDetails(String fullError) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error de descarga'),
        content: SingleChildScrollView(child: SelectableText(fullError)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDownloadOptions(YouTubeVideo video) async {
    final method = await showModalBottomSheet<DownloadMethod>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Opciones de descarga',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final option in DownloadMethod.values)
              ListTile(
                leading: const Icon(Icons.download),
                title: Text('Reintentar: ${option.label}'),
                subtitle: Text(option.description),
                onTap: () => Navigator.of(sheetContext).pop(option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || method == null) {
      return;
    }
    await _downloadVideo(video, method: method);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: _snackBarDuration),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewTitles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              onPressed: _isScanning ? null : _rescanMusic,
              tooltip: 'Escanear música',
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSelectedView(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerBar(
            player: _player,
            isExpanded: _isPlayerExpanded,
            onExpandChanged: (expanded) =>
                setState(() => _isPlayerExpanded = expanded),
            onToggle: _togglePlayback,
            onNext: _playNextInQueue,
            onPrevious: _playPreviousInQueue,
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.download_outlined),
                selectedIcon: Icon(Icons.download),
                label: 'Descargar',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Recomendaciones',
              ),
              NavigationDestination(
                icon: Icon(Icons.ondemand_video_outlined),
                selectedIcon: Icon(Icons.ondemand_video),
                label: 'Visor YouTube',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return PlaylistsView(
          playlists: _playlists,
          onCreatePlaylist: _createPlaylist,
          onOpenPlaylist: _openPlaylist,
        );
      case 1:
        return _buildDownloadView();
      case 2:
        return _buildRecommendationsView();
      case 3:
        return _buildViewerView();
      default:
        return PlaylistsView(
          playlists: _playlists,
          onCreatePlaylist: _createPlaylist,
          onOpenPlaylist: _openPlaylist,
        );
    }
  }

  Widget _buildDownloadView() => YouTubeSearchView(
    section: YouTubeSection.download,
    title: 'Buscar vídeos para descargar su audio MP3',
    controller: _downloadSearchController,
    results: _downloadResults,
    isSearching: _isDownloadingSearch,
    error: _downloadError,
    downloadingVideoIds: _downloadingVideoIds,
    downloadProgress: _downloadProgress,
    onSearch: _searchYouTube,
    onDownload: _downloadVideo,
    onShowDownloadOptions: _showDownloadOptions,
    onOpenVideo: _openYouTubeVideo,
  );

  Widget _buildViewerView() => YouTubeSearchView(
    section: YouTubeSection.viewer,
    title: 'Buscar vídeos en YouTube',
    controller: _viewerSearchController,
    results: _viewerResults,
    isSearching: _isViewerSearching,
    error: _viewerError,
    downloadingVideoIds: _downloadingVideoIds,
    downloadProgress: _downloadProgress,
    onSearch: _searchYouTube,
    onDownload: _downloadVideo,
    onShowDownloadOptions: _showDownloadOptions,
    onOpenVideo: _openYouTubeVideo,
  );

  Widget _buildRecommendationsView() {
    final recommendations = _recommendationService.recommend(
      playlists: _playlists,
      libraryTracks: _libraryTracks,
      downloads: _downloads,
    );
    return RecommendationsView(
      queue: recommendations
          .map((recommendation) => recommendation.track)
          .toList(growable: false),
      scores: recommendations
          .map((recommendation) => recommendation.score)
          .toList(growable: false),
      onPlayAt: (index) => _playTracks(
        recommendations
            .map((recommendation) => recommendation.track)
            .toList(growable: false),
        startIndex: index,
      ),
    );
  }
}
