// lib/providers/explore_provider.dart

import 'package:flutter/foundation.dart';
import '../data/models/track_model.dart';
import '../data/network/lyrics/lrclib_service.dart';
import '../data/network/youtube/youtube_service.dart';
import '../data/network/itunes/itunes_service.dart';

class ExploreProvider extends ChangeNotifier {
  List<TrackModel> trendingTracks = [];
  bool isLoading = false;
  String? error;

  String currentCategory = 'Trending';
  String currentQuery = '';
  String currentSource = 'youtube'; // 'youtube' or 'itunes'

  final LrcLibService _lrcLibService = LrcLibService();
  final YoutubeService _youtubeService = YoutubeService();
  final ItunesService _itunesService = ItunesService();

  Future<void> fetchTrending({
    String query = '',
    String categoryName = 'Trending',
    String? source,
  }) async {
    currentCategory = categoryName;
    currentQuery = query;
    if (source != null) {
      currentSource = source;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final searchTerm = query.isEmpty ? 'Top music hits 2024' : query;
      
      List<TrackModel> tracks = [];
      if (currentSource == 'itunes') {
         tracks = await _itunesService.searchSongs(searchTerm);
      } else {
         tracks = await _youtubeService.searchSongs(searchTerm);
      }

      // Map audioUrl using deferred stream URL extraction
      trendingTracks = tracks
          .map(
            (t) => t.copyWith(
              audioUrl: '', // This will be handled on play
            ),
          )
          .toList();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get audio url for dynamically resolved sources like YouTube
  Future<String> getAudioUrl(TrackModel track) async {
    if (track.source == 'youtube') {
      return await _youtubeService.getStreamUrl(track.id);
    } else if (track.source == 'itunes') {
      try {
        final searchResults = await _youtubeService.searchSongs("${track.title} ${track.artist}", limit: 1);
        if (searchResults.isNotEmpty) {
          return await _youtubeService.getStreamUrl(searchResults.first.id);
        }
      } catch (_) {
        // Fallback to preview url
      }
      return track.audioUrl;
    }
    return track.audioUrl;
  }

  /// Get audio url specifically for downloading (ensures audio-only stream so metadata works)
  Future<String> getDownloadUrl(TrackModel track) async {
    if (track.source == 'youtube') {
      return await _youtubeService.getDownloadStreamUrl(track.id);
    }
    return track.audioUrl;
  }

  /// Get actual download stream to bypass 403 Forbidden
  Future<Map<String, dynamic>?> getDownloadStream(TrackModel track) async {
    if (track.source == 'youtube') {
      return await _youtubeService.getDownloadStream(track.id);
    }
    return null;
  }

  Future<TrackModel> fetchLyrics(TrackModel track) async {
    try {
      final result = await _lrcLibService.getLyrics(
        trackName: track.title,
        artistName: track.artist,
        albumName: track.album,
        durationSeconds: track.duration.inSeconds,
      );

      if (result != null && result.hasLyrics) {
        return track.copyWith(
          lyrics: result.plainLyrics ?? '',
          syncedLyrics: result.syncedLyrics ?? '',
        );
      }
    } catch (_) {}
    return track;
  }

  @override
  void dispose() {
    _lrcLibService.dispose();
    _youtubeService.dispose();
    super.dispose();
  }
}
