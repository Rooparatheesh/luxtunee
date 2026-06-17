// lib/providers/player_provider.dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../data/models/track_model.dart';
import '../data/repositories/local_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final LocalRepository _repo = LocalRepository();

  ConcatenatingAudioSource? _playlist;
  List<TrackModel> tracks = []; // The complete local library
  List<TrackModel> queue = [];  // The currently active playlist/queue
  TrackModel? currentTrack;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;

  List<TrackModel> favoriteTracks = [];

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void toggleFavorite(TrackModel track) {
    final index = favoriteTracks.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      favoriteTracks.removeAt(index);
    } else {
      favoriteTracks.insert(0, track.copyWith(isFavorite: true));
    }
    notifyListeners();
  }

  bool isFavorite(TrackModel track) {
    return favoriteTracks.any((t) => t.id == track.id);
  }

  PlayerProvider() {
    _player.positionStream.listen((pos) {
      position = pos;
    });
    _player.durationStream.listen((dur) {
      if (dur != null) duration = dur;
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.isNotEmpty) {
        if (_currentResolver != null) {
          // Dynamic single-track playlist. The index from just_audio is always 0.
          // Do nothing, currentTrack is already correctly managed by playTrack and skipNext.
        } else {
          // Full ConcatenatingAudioSource (e.g. Local Library).
          if (index < queue.length) {
            currentTrack = queue[index];
            notifyListeners();
          }
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

  Future<void> playTrack(TrackModel track, {Future<String> Function(TrackModel)? urlResolver, List<TrackModel>? newQueue}) async {
    // Instantly update the UI so it feels snappy and doesn't lag
    currentTrack = track;
    if (urlResolver != null) _currentResolver = urlResolver;
    
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

    // Resolve URL for the current track if a resolver is provided and the URL is empty
    if (urlResolver != null && track.playbackSource.isEmpty) {
      final resolvedUrl = await urlResolver(track);
      // Update the track in our queue with the new URL
      queue[targetIndex] = track.copyWith(audioUrl: resolvedUrl);
      track = queue[targetIndex];
    }
    
    // Build playlist for just_audio_background
    final children = queue.map((t) {
      final isRemote = !t.isLocal;
      final artUri = isRemote && t.albumArt.isNotEmpty 
          ? Uri.parse(t.albumArt) 
          : Uri.parse('content://media/external/audio/albumart/${t.albumId ?? 0}');
      
      final url = t.playbackSource.isNotEmpty ? t.playbackSource : 'http://dummy.url/empty.mp3';

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

    // If we rely on dynamic URL resolution (like YouTube), building a full ConcatenatingAudioSource 
    // with dummy URLs causes just_audio to crash when pre-buffering the next track.
    // As a workaround, we only provide the current track to the player.
    if (urlResolver != null && queue[targetIndex].playbackSource.isNotEmpty) {
      _playlist = ConcatenatingAudioSource(children: [children[targetIndex]]);
      await _player.setAudioSource(_playlist!, initialIndex: 0);
    } else {
      _playlist = ConcatenatingAudioSource(children: children);
      await _player.setAudioSource(_playlist!, initialIndex: targetIndex);
    }

    await _player.play();
  }

  Future<void> togglePlayPause() async {
    isPlaying ? await _player.pause() : await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // We store the current resolver so we can reuse it when skipping tracks
  Future<String> Function(TrackModel)? _currentResolver;

  Future<void> skipNext() async {
    if (queue.isEmpty) return;
    final currentIndex = queue.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex >= 0 && currentIndex < queue.length - 1) {
      await playTrack(queue[currentIndex + 1], urlResolver: _currentResolver);
    }
  }

  Future<void> skipPrev() async {
    if (queue.isEmpty) return;
    final currentIndex = queue.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex > 0) {
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
