// lib/presentation/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/explore_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _categories = [
    {'name': 'Trending', 'query': ''},
    {'name': 'Hindi Hits', 'query': 'bollywood hindi'},
    {'name': 'Tamil', 'query': 'tamil songs'},
    {'name': 'Malayalam', 'query': 'malayalam songs'},
    {'name': 'Telugu', 'query': 'telugu songs'},
    {'name': 'K-Pop', 'query': 'kpop'},
    {'name': 'Global', 'query': 'top hits'},
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ExploreProvider>().trendingTracks.isEmpty) {
        context.read<ExploreProvider>().fetchTrending();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Explore Online',
                style: AppTypography.display(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.libraryTextGreen,
                ),
              ),
            ),
            
            const SizedBox(height: 16),


            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.body(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search for any song or language...',
                          hintStyle: AppTypography.body(color: AppColors.textMuted),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            context.read<ExploreProvider>().fetchTrending(
                              query: value.trim(),
                              categoryName: 'Search Results',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Language/Genre Pills
            SizedBox(
              height: 36,
              child: Consumer<ExploreProvider>(
                builder: (context, explore, child) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = explore.currentCategory == category['name'];
                      
                      return GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          explore.fetchTrending(
                            query: category['query']!,
                            categoryName: category['name']!,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.libraryPillActiveBg : AppColors.libraryPillBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category['name']!,
                            style: AppTypography.label(
                              color: isSelected ? Theme.of(context).colorScheme.onSurface : AppColors.textLight,
                              weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Online Track List
            Expanded(
              child: Consumer<ExploreProvider>(
                builder: (context, explore, child) {
                  if (explore.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.libraryTextGreen),
                    );
                  }
                  
                  if (explore.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            explore.error!,
                            style: AppTypography.body(color: Theme.of(context).colorScheme.onSurface, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => explore.fetchTrending(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.libraryPillActiveBg,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (explore.trendingTracks.isEmpty) {
                    return Center(
                      child: Text(
                        'No trending music found',
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    );
                  }
                  
                  // Connect to PlayerProvider to check current playing track
                  return Consumer<PlayerProvider>(
                    builder: (context, player, child) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100), 
                        itemCount: explore.trendingTracks.length,
                        itemBuilder: (context, index) {
                          final track = explore.trendingTracks[index];
                          final isPlaying = player.currentTrack?.id == track.id;
                          
                          return GestureDetector(
                            onTap: () {
                              player.playTrack(
                                track,
                                urlResolver: explore.getAudioUrl,
                                newQueue: explore.trendingTracks,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  // Album Art Square
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: track.albumArt,
                                      fit: BoxFit.cover,
                                      fadeInDuration: Duration.zero,
                                      fadeOutDuration: Duration.zero,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.libraryTextGreen),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Track Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          track.title,
                                          style: AppTypography.body(
                                            size: 15,
                                            weight: FontWeight.w600,
                                            color: isPlaying ? AppColors.libraryTextGreen : Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${track.artist} • ${track.formattedDuration}',
                                          style: AppTypography.label(
                                            size: 12,
                                            color: AppColors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Play Icon
                                  Icon(
                                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                                    color: isPlaying ? AppColors.libraryTextGreen : AppColors.textMuted,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
