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
  List<TrackModel> tracks = [];
  TrackModel? currentTrack;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  PlayerProvider() {
    _player.positionStream.listen((pos) {
      position = pos;
    });
    _player.durationStream.listen((dur) {
      if (dur != null) duration = dur;
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && tracks.isNotEmpty && index < tracks.length) {
        currentTrack = tracks[index];
        notifyListeners();
      }
    });
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        // Automatically play next track if we're using dynamic resolution and track finishes
        if (_currentResolver != null) {
          skipNext();
        }
      }
      notifyListeners();
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

  Future<void> playTrack(TrackModel track, {Future<String> Function(TrackModel)? urlResolver}) async {
    // Instantly update the UI so it feels snappy and doesn't lag
    currentTrack = track;
    if (urlResolver != null) _currentResolver = urlResolver;
    notifyListeners();

    if (tracks.isEmpty) {
      tracks = [track];
    }
    
    final initialIndex = tracks.indexWhere((t) => t.id == track.id);
    final targetIndex = initialIndex >= 0 ? initialIndex : 0;

    // Resolve URL for the current track if a resolver is provided and the URL is empty
    if (urlResolver != null && track.playbackSource.isEmpty) {
      final resolvedUrl = await urlResolver(track);
      // Update the track in our list with the new URL
      tracks[targetIndex] = track.copyWith(audioUrl: resolvedUrl);
      track = tracks[targetIndex];
    }
    
    // Build playlist for just_audio_background
    final children = tracks.map((t) {
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
    if (urlResolver != null && tracks[targetIndex].playbackSource.isNotEmpty) {
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
    if (tracks.isEmpty) return;
    final currentIndex = tracks.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex >= 0 && currentIndex < tracks.length - 1) {
      await playTrack(tracks[currentIndex + 1], urlResolver: _currentResolver);
    }
  }

  Future<void> skipPrev() async {
    if (tracks.isEmpty) return;
    final currentIndex = tracks.indexWhere((t) => t.id == currentTrack?.id);
    if (currentIndex > 0) {
      await playTrack(tracks[currentIndex - 1], urlResolver: _currentResolver);
    }
  }

  void removeTrack(TrackModel track) {
    tracks.removeWhere((t) => t.id == track.id);
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
