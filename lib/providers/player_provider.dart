// lib/providers/player_provider.dart
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/track_model.dart';
import '../data/repositories/local_repository.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final LocalRepository _repo = LocalRepository();

  List<TrackModel> tracks = [];
  TrackModel? currentTrack;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isLoading = false;

  PlayerProvider() {
    _player.positionStream.listen((pos) {
      position = pos;
      notifyListeners();
    });
    _player.durationStream.listen((dur) {
      if (dur != null) duration = dur;
      notifyListeners();
    });
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
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

  Future<void> playTrack(TrackModel track) async {
    currentTrack = track;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(track.uri)));
    await _player.play();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    isPlaying ? await _player.pause() : await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (currentTrack == null || tracks.isEmpty) return;
    final idx = tracks.indexWhere((t) => t.id == currentTrack!.id);
    if (idx < tracks.length - 1) await playTrack(tracks[idx + 1]);
  }

  Future<void> skipPrev() async {
    if (currentTrack == null || tracks.isEmpty) return;
    final idx = tracks.indexWhere((t) => t.id == currentTrack!.id);
    if (idx > 0) await playTrack(tracks[idx - 1]);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
