// lib/providers/explore_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/track_model.dart';

class ExploreProvider extends ChangeNotifier {
  List<TrackModel> trendingTracks = [];
  bool isLoading = false;
  String? error;
  
  String currentCategory = 'Trending';
  String currentQuery = 'pop';

  Future<void> fetchTrending({String query = 'pop', String categoryName = 'Trending'}) async {
    currentCategory = categoryName;
    currentQuery = query;
    
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Free iTunes Search API for public demo
      // URL encode the query to handle spaces and special characters safely
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('https://itunes.apple.com/search?term=$encodedQuery&limit=25&media=music&entity=song');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        trendingTracks = results.map((item) {
          // iTunes provides high-res artwork if we replace '100x100' with something bigger
          String artwork = item['artworkUrl100'] ?? '';
          artwork = artwork.replaceAll('100x100bb', '600x600bb');
          
          return TrackModel(
            id: item['trackId'].toString(),
            title: item['trackName'] ?? 'Unknown',
            artist: item['artistName'] ?? 'Unknown',
            album: item['collectionName'] ?? 'Unknown',
            duration: Duration(milliseconds: item['trackTimeMillis'] ?? 0),
            audioUrl: item['previewUrl'] ?? '', // 30s audio preview
            albumArt: artwork,
          );
        }).where((t) => t.audioUrl.isNotEmpty).toList();
      } else {
        error = 'Failed to load music';
      }
    } catch (e) {
      error = 'Check your internet connection';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
