// lib/providers/player_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../data/models/track_model.dart';
import '../data/repositories/local_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final LocalRepository _repo = LocalRepository();

  ConcatenatingAudioSource? _playlist;
  List<TrackModel> tracks = []; // The complete local library
  List<TrackModel> queue = []; // The currently active playlist/queue
  TrackModel? currentTrack;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;
  bool _ignoreIndexChanges = false;

  List<TrackModel> favoriteTracks = [];

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  static const _favoritesKey = 'favorite_tracks';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList(_favoritesKey);
    if (favList != null) {
      favoriteTracks = favList.map((str) => TrackModel.fromJson(json.decode(str))).toList();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = favoriteTracks.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList(_favoritesKey, favList);
  }

  void toggleFavorite(TrackModel track) {
    final index = favoriteTracks.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      favoriteTracks.removeAt(index);
    } else {
      favoriteTracks.insert(0, track.copyWith(isFavorite: true));
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(TrackModel track) {
    return favoriteTracks.any((t) => t.id == track.id);
  }

  PlayerProvider() {
    _loadFavorites();
    _player.positionStream.listen((pos) {
      position = pos;
    });
    _player.durationStream.listen((dur) {
      if (dur != null) duration = dur;
    });
    _player.currentIndexStream.listen((index) {
      if (_ignoreIndexChanges) return;
      if (index != null && queue.isNotEmpty && index < queue.length) {
        if (_currentResolver != null) {
          // Only handle if this is a genuinely new track (not re-triggered by our own playTrack call)
          if (queue[index].id != currentTrack?.id) {
            _handleBackgroundSkip(index);
          }
        } else {
          currentTrack = queue[index];
          notifyListeners();
        }
      }
    });
    _player.playerStateStream.listen((state) {
      bool shouldNotify = false;
      if (isPlaying != state.playing) {
        isPlaying = state.playing;
        shouldNotify = true;
      }

      if (state.processingState == ProcessingState.completed) {
        // Automatically play next track if we're using dynamic resolution and track finishes
        if (_currentResolver != null) {
          skipNext();
        }
      }

      if (shouldNotify) notifyListeners();
    });
  }

  Future<void> loadLibrary() async {
    isLoading = true;
    notifyListeners();

    final granted = await _repo.requestPermission();
    if (granted) {
      tracks = await _repo.fetchTracks();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> scanMedia(String path) async {
    await _repo.scanMedia(path);
  }

  void addDownloadedTrack(TrackModel track, String path) {
    // Add to local tracks list immediately so it shows up in UI
    final localTrack = track.copyWith(
      id: track.id, // Keep the same ID so we can match it later if needed
      uri: path, // Treat as local file
      source: 'local',
      audioUrl: '', // No longer needs network URL
    );

    // Avoid duplicates if we already have it
    if (!tracks.any((t) => t.uri == localTrack.uri)) {
      tracks.insert(0, localTrack);
      notifyListeners();
    }
  }

  Future<void> playTrack(
    TrackModel track, {
    Future<String> Function(TrackModel)? urlResolver,
    List<TrackModel>? newQueue,
  }) async {
    // Instantly update the UI so it feels snappy and doesn't lag
    currentTrack = track;
    if (urlResolver != null) {
      _currentResolver = urlResolver;
    } else if (track.isLocal) {
      // If we are playing a local track, clear the previous resolver
      // so YouTube background logic doesn't interfere.
      _currentResolver = null;
    }

    // Update the queue if a new one is provided, otherwise keep existing queue
    if (newQueue != null) {
      queue = List.from(newQueue);
    } else if (queue.isEmpty) {
      queue = List.from(tracks);
    }

    notifyListeners();

    if (queue.isEmpty) {
      queue = [track];
    }

    final initialIndex = queue.indexWhere((t) => t.id == track.id);
    final targetIndex = initialIndex >= 0 ? initialIndex : 0;

    // Auto-attach resolver for YouTube tracks if none provided
    final effectiveResolver = urlResolver ?? _currentResolver;

    // Resolve URL for the current track if a resolver is available and the URL is empty
    if (effectiveResolver != null && track.playbackSource.isEmpty) {
      final resolvedUrl = await effectiveResolver(track);
      // Update the track in our queue with the new URL
      queue[targetIndex] = track.copyWith(audioUrl: resolvedUrl);
      track = queue[targetIndex];
    }

    // Build playlist with ALL queue items so background notification shows prev/next
    final children = queue.map((t) {
      final isRemote = !t.isLocal;
      final artUri = isRemote && t.albumArt.isNotEmpty
          ? Uri.parse(t.albumArt)
          : Uri.parse(
              'content://media/external/audio/albumart/${t.albumId ?? 0}',
            );

      // Use a dummy URL for unresolved tracks — skipNext/skipPrev resolve real URLs before playing
      final url = t.playbackSource.isNotEmpty
          ? t.playbackSource
          : 'https://example.com/placeholder.mp3';

      return AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: t.id.toString(),
          album: t.album,
          title: t.title,
          artist: t.artist,
          artUri: artUri,
        ),
      );
    }).toList();

    _ignoreIndexChanges = true;
    try {
      // Always build the full playlist so the notification shows prev/next buttons
      _playlist = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(_playlist!, initialIndex: targetIndex);
    } finally {
      _ignoreIndexChanges = false;
    }

    await _player.play();
  }

  Future<void> togglePlayPause() async {
    isPlaying ? await _player.pause() : await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<String> Function(TrackModel)? _currentResolver;
  bool _isHandlingBackgroundSkip = false;

  /// Called when background notification triggers skip via currentIndexStream.
  /// Resolves URL for the new track and plays it properly.
  Future<void> _handleBackgroundSkip(int index) async {
    if (_isHandlingBackgroundSkip) return; // Prevent re-entrant calls
    _isHandlingBackgroundSkip = true;

    try {
      final track = queue[index];
      currentTrack = track;
      notifyListeners();

      // Resolve URL if needed
      if (_currentResolver != null && track.playbackSource.isEmpty) {
        try {
          final resolvedUrl = await _currentResolver!(track);
          queue[index] = track.copyWith(audioUrl: resolvedUrl);
        } catch (_) {}
      }

      await playTrack(queue[index], urlResolver: _currentResolver);
    } finally {
      _isHandlingBackgroundSkip = false;
    }
  }

  Future<void> skipNext() async {
    if (queue.isEmpty) return;
    final currentIndex = queue.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex >= 0 && currentIndex < queue.length - 1) {
      final nextTrack = queue[currentIndex + 1];
      // Resolve URL for the next track before playing
      if (_currentResolver != null && nextTrack.playbackSource.isEmpty) {
        try {
          final resolvedUrl = await _currentResolver!(nextTrack);
          queue[currentIndex + 1] = nextTrack.copyWith(audioUrl: resolvedUrl);
        } catch (_) {}
      }
      await playTrack(queue[currentIndex + 1], urlResolver: _currentResolver);
    }
  }

  Future<void> skipPrev() async {
    if (queue.isEmpty) return;
    final currentIndex = queue.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex > 0) {
      final prevTrack = queue[currentIndex - 1];
      // Resolve URL for the previous track before playing
      if (_currentResolver != null && prevTrack.playbackSource.isEmpty) {
        try {
          final resolvedUrl = await _currentResolver!(prevTrack);
          queue[currentIndex - 1] = prevTrack.copyWith(audioUrl: resolvedUrl);
        } catch (_) {}
      }
      await playTrack(queue[currentIndex - 1], urlResolver: _currentResolver);
    }
  }

  void removeTrack(TrackModel track) {
    tracks.removeWhere((t) => t.id == track.id);
    queue.removeWhere((t) => t.id == track.id);
    if (currentTrack?.id == track.id) {
      _player.stop();
      currentTrack = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
