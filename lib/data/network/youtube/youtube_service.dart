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

        // Use highResUrl (hqdefault.jpg) as it is practically guaranteed to exist,
        // avoiding 404 errors that occur when maxresdefault.jpg is missing.
        final albumArt = video.thumbnails.highResUrl;

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
  Future<String> getStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      StreamInfo? streamInfo;

      try {
        // Muxed streams (video+audio) are much less likely to return 403 Forbidden on ExoPlayer
        streamInfo = manifest.muxed.withHighestBitrate();
      } catch (_) {
        // Fallback to audioOnly if muxed is missing (e.g. Official Music tracks)
        try {
          final mp4Audio = manifest.audioOnly.where(
            (s) => s.container.name == 'mp4',
          );
          if (mp4Audio.isNotEmpty) {
            streamInfo = mp4Audio.withHighestBitrate();
          } else {
            streamInfo = manifest.audioOnly.withHighestBitrate();
          }
        } catch (_) {
          // If all else fails
          streamInfo = manifest.audioOnly.first;
        }
      }

      return streamInfo.url.toString();
    } catch (e) {
      throw Exception('Failed to get YouTube stream URL: $e');
    }
  }

  /// Extracts the highest quality audio-only stream URL for a given video ID (for downloading).
  Future<String> getDownloadStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      StreamInfo? streamInfo;

      try {
        final mp4Audio = manifest.audioOnly.where(
          (s) => s.container.name == 'mp4',
        );
        if (mp4Audio.isNotEmpty) {
          streamInfo = mp4Audio.withHighestBitrate();
        } else if (manifest.audioOnly.isNotEmpty) {
          streamInfo = manifest.audioOnly.withHighestBitrate();
        } else {
          streamInfo = manifest.muxed.withHighestBitrate();
        }
      } catch (_) {
        if (manifest.audioOnly.isNotEmpty) {
          streamInfo = manifest.audioOnly.first;
        } else {
          streamInfo = manifest.muxed.withHighestBitrate();
        }
      }

      return streamInfo.url.toString();
    } catch (e) {
      throw Exception('Failed to get YouTube download stream URL: $e');
    }
  }

  /// Gets the actual stream of bytes using YoutubeExplode's internal client to bypass 403
  /// Automatically retries up to 3 times with delay to handle rate limiting.
  Future<Map<String, dynamic>> getDownloadStream(String videoId) async {
    const maxRetries = 3;
    int attempt = 0;

    while (true) {
      try {
        // Re-fetch the manifest on every retry to get a fresh URL
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);
        StreamInfo? streamInfo;

        try {
          final mp4Audio = manifest.audioOnly.where(
            (s) => s.container.name == 'mp4',
          );
          if (mp4Audio.isNotEmpty) {
            streamInfo = mp4Audio.withHighestBitrate();
          } else if (manifest.audioOnly.isNotEmpty) {
            streamInfo = manifest.audioOnly.withHighestBitrate();
          } else {
            streamInfo = manifest.muxed.withHighestBitrate();
          }
        } catch (_) {
          if (manifest.audioOnly.isNotEmpty) {
            streamInfo = manifest.audioOnly.first;
          } else {
            streamInfo = manifest.muxed.withHighestBitrate();
          }
        }

        final stream = _yt.videos.streamsClient.get(streamInfo);
        return {
          'stream': stream,
          'size': streamInfo.size.totalBytes,
        };
      } catch (e) {
        attempt++;
        final isRateLimit = e.toString().contains('RequestLimitExceeded') ||
            e.toString().contains('rate limit') ||
            e.toString().contains('429');

        if (attempt >= maxRetries || !isRateLimit) {
          throw Exception('Failed to get YouTube download stream: $e');
        }

        // Exponential backoff: 3s, 6s, 12s
        final waitSeconds = 3 * (1 << (attempt - 1));
        print('YouTube rate limited. Retrying in ${waitSeconds}s... (attempt $attempt/$maxRetries)');
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }
  }


  Future<TrackModel> getTrackFromId(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return TrackModel(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        album: 'YouTube',
        duration: video.duration ?? Duration.zero,
        audioUrl: '', // This will be fetched on demand
        albumArt: video.thumbnails.highResUrl,
        source: 'youtube',
      );
    } catch (e) {
      throw Exception('Failed to get YouTube video details: $e');
    }
  }

  void dispose() {
    _yt.close();
  }
}
