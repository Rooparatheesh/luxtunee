import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luxtunee/utils/pairing_utils.dart';
import 'package:luxtunee/providers/player_provider.dart';
import 'package:luxtunee/data/models/track_model.dart';
import 'package:luxtunee/data/network/youtube/youtube_service.dart';
import 'dart:async';

class PartyProvider extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  String? _myDeviceId;
  String? _currentRoomCode;
  bool _isHost = false; // Kept for legacy/cleanup logic
  bool _isSyncing = false; // Flag to prevent echo loops
  
  StreamSubscription<DatabaseEvent>? _roomPlaybackSubscription;
  PlayerProvider? _playerProvider;
  StreamSubscription? _playerPosSubscription;
  final YoutubeService _youtubeService = YoutubeService();

  // Throttling state
  int _lastSyncTimeMs = 0;
  int _lastPosMs = 0;
  bool _lastIsPlaying = false;
  String? _lastTrackId;

  String? get currentRoomCode => _currentRoomCode;
  bool get isHost => _isHost;
  bool get isGuest => _currentRoomCode != null && !_isHost;

  Future<void> initialize() async {
    _myDeviceId = await PairingUtils.getDeviceId();
  }

  void attachPlayer(PlayerProvider player) {
    _playerProvider = player;
    
    // Listen to local player and broadcast changes to the room
    _playerPosSubscription = player.positionStream.listen((pos) {
      if (_currentRoomCode == null || player.currentTrack == null || _isSyncing) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final currentPosMs = pos.inMilliseconds;
      final isPlaying = player.isPlaying;
      final currentTrackId = player.currentTrack!.id;

      bool shouldSync = false;

      // 1. Play state changed
      if (isPlaying != _lastIsPlaying) {
        shouldSync = true;
      }
      // 2. Track changed
      else if (currentTrackId != _lastTrackId) {
        shouldSync = true;
      }
      // 3. User seeked
      // Since position naturally increases, a large unexpected jump means seek.
      else if ((currentPosMs - _lastPosMs).abs() > 1000 && (now - _lastSyncTimeMs) > 500) {
        shouldSync = true;
      }
      // 4. Heartbeat (every 5 seconds)
      else if (now - _lastSyncTimeMs > 5000) {
        shouldSync = true;
      }

      if (shouldSync) {
        _lastSyncTimeMs = now;
        _lastPosMs = currentPosMs;
        _lastIsPlaying = isPlaying;
        _lastTrackId = currentTrackId;

        updatePlaybackState(
          track: player.currentTrack!,
          isPlaying: isPlaying,
          positionMs: currentPosMs,
        );
      } else {
        // Just update lastPosMs so we can detect seeks accurately
        _lastPosMs = currentPosMs;
      }
    });
  }

  Future<String?> startParty() async {
    try {
      if (_myDeviceId == null) await initialize();
      
      _currentRoomCode = PairingUtils.generatePairingCode();
      _isHost = true;
      
      await _db.child('rooms/$_currentRoomCode').set({
        'host_device_id': _myDeviceId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }).timeout(const Duration(seconds: 10));
      
      // Reset throttling state
      _lastSyncTimeMs = 0;
      _lastPosMs = 0;

      // Make sure we have the initial state published
    if (_playerProvider?.currentTrack != null) {
       updatePlaybackState(
          track: _playerProvider!.currentTrack!,
          isPlaying: _playerProvider!.isPlaying,
          positionMs: _playerProvider!.position.inMilliseconds,
       );
    }
      
      _startListeningToRoom();
      notifyListeners();
      return _currentRoomCode;
    } catch (e) {
      debugPrint("Start party error: $e");
      _currentRoomCode = null;
      _isHost = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinParty(String code) async {
    try {
      if (_myDeviceId == null) await initialize();

      final snapshot = await _db.child('rooms/$code').get().timeout(const Duration(seconds: 10));
      if (snapshot.exists) {
        _currentRoomCode = code;
        _isHost = false;
        
        _startListeningToRoom();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Join party error: $e");
      return false;
    }
  }

  void _startListeningToRoom() {
    _roomPlaybackSubscription?.cancel();
    if (_currentRoomCode == null) return;

    _roomPlaybackSubscription = _db.child('rooms/$_currentRoomCode').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final roomData = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (roomData.containsKey('playback_state')) {
          final state = Map<String, dynamic>.from(roomData['playback_state'] as Map);
          if (_playerProvider != null && state['track_url'] != null) {
             _syncRemotePlayer(state);
          }
        }
      } else {
        // Room was deleted
        leaveParty();
      }
    });
  }

  Future<void> _syncRemotePlayer(Map<String, dynamic> state) async {
    if (_playerProvider == null) return;
    
    final updatedBy = state['updated_by'];
    // Ignore updates that we just sent ourselves
    if (updatedBy == _myDeviceId) return;
    
    _isSyncing = true; // Block local broadcasts while we sync

    try {
      final trackId = state['track_id'];
      final isPlaying = state['is_playing'];
      final positionMs = state['position_ms'];
      final updatedAt = state['updated_at'];
      final trackSource = state['track_source'] ?? 'online';
      
      // Ignore device clocks for latency because device clocks can be skewed.
      // Instead, apply a small fixed offset (e.g. 300ms) to compensate for network delay.
      final adjustedPosition = positionMs + (isPlaying ? 300 : 0);
      
      // 1. Handle Track Switch
      if (_playerProvider!.currentTrack?.id != trackId) {
        // Find track in local library/explore list
        TrackModel? track = _playerProvider!.tracks.where((t) => t.id == trackId).firstOrNull;
        
        // If the track isn't local, construct it from the broadcasted metadata
        if (track == null && state['track_title'] != null) {
          track = TrackModel(
            id: trackId,
            title: state['track_title'] ?? 'Unknown',
            artist: state['track_artist'] ?? 'Unknown',
            album: 'Party Mode',
            duration: Duration(milliseconds: state['track_duration_ms'] ?? 0),
            // If it's youtube, we CANNOT use the broadcasted URL because it's IP-locked.
            // Leave it empty so it can be dynamically resolved.
            audioUrl: trackSource == 'youtube' ? '' : (state['track_url'] ?? ''),
            albumArt: state['track_album_art'] ?? '',
            source: trackSource,
          );
        }

        if (track != null) {
           if (trackSource == 'youtube') {
             await _playerProvider!.playTrack(track, urlResolver: (t) => _youtubeService.getStreamUrl(t.id));
           } else {
             await _playerProvider!.playTrack(track);
           }
        }
      }
      
      // 2. Handle Position Sync (Tolerate up to 1000ms drift to prevent stuttering)
      final currentPosMs = _playerProvider!.position.inMilliseconds;
      if ((currentPosMs - adjustedPosition).abs() > 1000) {
        await _playerProvider!.seek(Duration(milliseconds: adjustedPosition));
      }
      
      // 3. Handle Play/Pause
      if (isPlaying && !_playerProvider!.isPlaying) {
        await _playerProvider!.togglePlayPause();
      } else if (!isPlaying && _playerProvider!.isPlaying) {
        await _playerProvider!.togglePlayPause();
      }
    } finally {
      // Keep the syncing flag active for a short period after applying changes
      // to absorb any delayed asynchronous stream events from the native audio player.
      // This prevents the echo loop (ping-ponging state).
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isSyncing = false;
      });
    }
  }

  Future<void> leaveParty() async {
    if (_isHost && _currentRoomCode != null) {
      // Delete the room so guests know it's over
      await _db.child('rooms/$_currentRoomCode').remove();
    }
    
    _roomPlaybackSubscription?.cancel();
    _currentRoomCode = null;
    _isHost = false;
    _isSyncing = false;
    
    notifyListeners();
  }

  Future<void> updatePlaybackState({
    required TrackModel track,
    required bool isPlaying,
    required int positionMs,
  }) async {
    if (_currentRoomCode == null) return;

    await _db.child('rooms/$_currentRoomCode/playback_state').set({
      'track_id': track.id,
      'track_url': track.playbackSource,
      'track_title': track.title,
      'track_artist': track.artist,
      'track_album_art': track.albumArt,
      'track_duration_ms': track.duration.inMilliseconds,
      'track_source': track.source,
      'is_playing': isPlaying,
      'position_ms': positionMs,
      'updated_by': _myDeviceId,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void dispose() {
    _roomPlaybackSubscription?.cancel();
    _playerPosSubscription?.cancel();
    _youtubeService.dispose();
    if (isHost) {
      leaveParty(); // Cleanup room if app is closed while hosting
    }
    super.dispose();
  }
}

