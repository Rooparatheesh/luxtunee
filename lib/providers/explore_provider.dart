// lib/providers/explore_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/track_model.dart';
import '../data/network/deezer/deezer_service.dart';
import '../data/network/lyrics/lrclib_service.dart';
import '../data/network/navidrome/navidrome_models.dart';
import '../data/network/navidrome/navidrome_service.dart';
import '../data/network/jellyfin/jellyfin_service.dart';
import '../data/network/netease/netease_service.dart';
import '../data/network/youtube/youtube_service.dart';

class ExploreProvider extends ChangeNotifier {
  List<TrackModel> trendingTracks = [];
  bool isLoading = false;
  String? error;

  String currentCategory = 'Trending';
  String currentQuery = '';
  String currentSource = 'Deezer'; // Deezer, Navidrome, Jellyfin, NetEase

  final DeezerService _deezerService = DeezerService();
  final LrcLibService _lrcLibService = LrcLibService();
  final NavidromeApiService _navidromeService = NavidromeApiService();
  final JellyfinApiService _jellyfinService = JellyfinApiService();
  final NeteaseApiService _neteaseService = NeteaseApiService();
  final YoutubeService _youtubeService = YoutubeService();

  void setSource(String source) {
    if (currentSource == source) return;
    currentSource = source;
    currentCategory = 'Trending';
    currentQuery = '';
    fetchTrending();
  }

  Future<void> fetchTrending({String query = '', String categoryName = 'Trending'}) async {
    currentCategory = categoryName;
    currentQuery = query;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      if (currentSource == 'Deezer') {
        final deezerTracks = query.isEmpty
            ? await _deezerService.getChartTracks(limit: 25)
            : await _deezerService.searchTracks(query, limit: 25);

        trendingTracks = deezerTracks.map((dt) {
          final albumArt = dt.album.coverXl.isNotEmpty
              ? dt.album.coverXl
              : dt.album.coverBig.isNotEmpty ? dt.album.coverBig : dt.album.coverMedium;
          return TrackModel(
            id: dt.id.toString(),
            title: dt.title,
            artist: dt.artist.name,
            album: dt.album.title,
            duration: Duration(seconds: dt.duration),
            audioUrl: dt.preview,
            albumArt: albumArt,
            source: 'deezer',
          );
        }).toList();

      } else if (currentSource == 'Navidrome') {
        final url = prefs.getString('navidrome_url') ?? '';
        final user = prefs.getString('navidrome_user') ?? '';
        final pass = prefs.getString('navidrome_pass') ?? '';
        if (url.isEmpty || user.isEmpty || pass.isEmpty) {
          throw Exception('Please configure Navidrome in Settings');
        }
        _navidromeService.setCredentials(NavidromeCredentials(serverUrl: url, username: user, password: pass));
        
        // Navidrome doesn't have a direct 'trending', we can use search with a generic query or getAlbumList
        // Let's just use searchSongs to get some random/initial tracks if query is empty
        final navidromeTracks = query.isEmpty 
            ? await _navidromeService.searchSongs('a') // simple generic query
            : await _navidromeService.searchSongs(query);
            
        trendingTracks = navidromeTracks.map((s) => s.toTrackModel(
          (id) => _navidromeService.getCoverArtUrl(id), 
          (id) => _navidromeService.getStreamUrl(id)
        )).toList();

      } else if (currentSource == 'Jellyfin') {
        final url = prefs.getString('jellyfin_url') ?? '';
        final user = prefs.getString('jellyfin_user') ?? '';
        final pass = prefs.getString('jellyfin_pass') ?? '';
        if (url.isEmpty || user.isEmpty || pass.isEmpty) {
          throw Exception('Please configure Jellyfin in Settings');
        }
        await _jellyfinService.authenticateByName(url, user, pass);
        
        final jellyfinTracks = query.isEmpty 
            ? await _jellyfinService.getMusicItems()
            : await _jellyfinService.searchSongs(query);
            
        trendingTracks = jellyfinTracks.map((s) => s.toTrackModel(
          (id) => _jellyfinService.getImageUrl(id), 
          (id) => _jellyfinService.getStreamUrl(id)
        )).toList();

      } else if (currentSource == 'NetEase') {
        // Just use search for NetEase as well, or a default query
        final neteaseTracks = query.isEmpty
            ? await _neteaseService.searchSongs('trending')
            : await _neteaseService.searchSongs(query);
            
        trendingTracks = neteaseTracks; // NeteaseService already returns TrackModel
      } else if (currentSource == 'YouTube') {
        final ytTracks = query.isEmpty
            ? await _youtubeService.searchSongs('Top music hits 2024')
            : await _youtubeService.searchSongs(query);

        // Map audioUrl using deferred stream URL extraction
        trendingTracks = ytTracks.map((t) => t.copyWith(
          audioUrl: '', // This will be handled on play
        )).toList();
      }

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
    }
    return track.audioUrl;
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
    _deezerService.dispose();
    _lrcLibService.dispose();
    _youtubeService.dispose();
    super.dispose();
  }
}
