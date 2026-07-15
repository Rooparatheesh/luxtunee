import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/track_model.dart';

class ItunesService {
  Future<List<TrackModel>> searchSongs(String query, {int limit = 25}) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=$limit',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((track) {
          // Convert 100x100 to 600x600 for high resolution album art
          String albumArt = track['artworkUrl100'] ?? '';
          if (albumArt.isNotEmpty) {
            albumArt = albumArt.replaceAll('100x100bb.jpg', '600x600bb.jpg');
          }

          return TrackModel(
            id: track['trackId'].toString(),
            title: track['trackName'] ?? 'Unknown Title',
            artist: track['artistName'] ?? 'Unknown Artist',
            album: track['collectionName'] ?? 'Unknown Album',
            duration: Duration(milliseconds: track['trackTimeMillis'] ?? 0),
            audioUrl: '', // Will fetch full audio from YouTube later
            albumArt: albumArt,
            source: 'itunes',
          );
        }).toList();
      } else {
        throw Exception('Failed to load iTunes search results');
      }
      return [];
    } catch (e) {
      throw Exception('iTunes API error: $e');
    }
  }

  /// Attempts to find iTunes metadata for a YouTube track by cleaning its title
  /// and searching iTunes. If found, returns a new TrackModel with the iTunes
  /// title, artist, album, and high-quality cover art.
  Future<TrackModel> enrichYouTubeTrack(TrackModel ytTrack) async {
    try {
      // Clean up YouTube title (remove "Official Video", etc.)
      String cleanTitle = ytTrack.title
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'(?i)official video|official audio|lyrics|lyric video|music video'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '') // Remove special chars
          .trim();
      
      // If title contains '-', assume it's "Artist - Title"
      String query = cleanTitle;
      if (cleanTitle.contains('-')) {
        final parts = cleanTitle.split('-');
        if (parts.length == 2) {
           query = '${parts[0].trim()} ${parts[1].trim()}';
        }
      }

      final results = await searchSongs(query, limit: 1);
      if (results.isNotEmpty) {
        final itunesTrack = results.first;
        // Merge iTunes metadata into the YouTube track, preserving the YouTube ID and audio source
        return ytTrack.copyWith(
          title: itunesTrack.title,
          artist: itunesTrack.artist,
          album: itunesTrack.album,
          albumArt: itunesTrack.albumArt,
        );
      }
    } catch (e) {
      // Ignore errors and return original track
    }
    return ytTrack;
  }
}
