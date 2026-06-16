import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../models/track_model.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Searches YouTube for a query and returns a list of generic TrackModels.
  /// We filter out live streams because they often don't have standard durations
  /// or are incompatible with audio players.
  Future<List<TrackModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      final searchResults = await _yt.search.search(query);
      
      final List<TrackModel> tracks = [];
      int count = 0;
      
      for (final video in searchResults) {
        if (count >= limit) break;
        if (video.isLive) continue; // Skip live streams
        
        final duration = video.duration ?? Duration.zero;
        if (duration == Duration.zero) continue;

        final albumArt = video.thumbnails.maxResUrl.isNotEmpty 
            ? video.thumbnails.maxResUrl 
            : video.thumbnails.highResUrl;

        tracks.add(
          TrackModel(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            album: 'YouTube',
            duration: duration,
            audioUrl: '', // This will be fetched on demand
            albumArt: albumArt,
            source: 'youtube',
          ),
        );
        count++;
      }
      return tracks;
    } catch (e) {
      throw Exception('YouTube API error: $e');
    }
  }

  /// Extracts the highest quality stream URL for a given video ID.
  /// We use `muxed` (video+audio) streams because YouTube often blocks pure DASH `audioOnly` 
  /// streams with a 403 Forbidden error in native players like ExoPlayer.
  Future<String> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      throw Exception('Failed to get YouTube stream URL: $e');
    }
  }

  void dispose() {
    _yt.close();
  }
}
