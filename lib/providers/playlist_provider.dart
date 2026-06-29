// lib/providers/playlist_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/playlist_model.dart';
import '../data/models/track_model.dart';

class PlaylistProvider extends ChangeNotifier {
  List<PlaylistModel> _playlists = [];
  bool _isLoading = true;

  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;

  final _uuid = const Uuid();
  static const String _storageKey = 'saved_playlists_v1';

  PlaylistProvider() {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getStringList(_storageKey);
      
      if (savedData != null) {
        _playlists = savedData.map((jsonStr) => PlaylistModel.fromJson(jsonStr)).toList();
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = _playlists.map((p) => p.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  Future<void> createPlaylist(String title) async {
    if (title.trim().isEmpty) return;
    
    final newPlaylist = PlaylistModel(
      id: _uuid.v4(),
      title: title.trim(),
      tracks: [],
    );
    
    _playlists.insert(0, newPlaylist); // Add to beginning
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> renamePlaylist(String id, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index != -1) {
      _playlists[index].title = newTitle.trim();
      notifyListeners();
      await _savePlaylists();
    }
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _savePlaylists();
  }

  Future<void> addTrackToPlaylist(String playlistId, TrackModel track) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      // Check if track is already in the playlist to avoid duplicates
      final isAlreadyAdded = _playlists[index].tracks.any((t) => t.id == track.id);
      if (!isAlreadyAdded) {
        _playlists[index].tracks.add(track);
        notifyListeners();
        await _savePlaylists();
      }
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index != -1) {
      _playlists[index].tracks.removeWhere((t) => t.id == trackId);
      notifyListeners();
      await _savePlaylists();
    }
  }
}
