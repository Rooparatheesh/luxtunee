// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _filters = ['SONGS', 'ALBUMS', 'ARTIST', 'PLAYLISTS'];
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlayerProvider>();
      if (provider.tracks.isEmpty) {
        provider.loadLibrary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library',
                    style: AppTypography.display(
                      size: 28,
                      weight: FontWeight.w700,
                      color: AppColors.libraryTextGreen,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.libraryPillActiveBg : AppColors.libraryPillBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _filters[index],
                        style: AppTypography.label(
                          size: 12,
                          weight: FontWeight.w600,
                          color: isSelected ? AppColors.white : AppColors.textLight,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Track List
            Expanded(
              child: Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  if (player.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.libraryTextGreen),
                    );
                  }
                  
                  if (player.tracks.isEmpty) {
                    return Center(
                      child: Text(
                        'No music found',
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    );
                  }
                  
                  // Ensure we pad the bottom so the mini player doesn't hide the last items
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100), 
                    itemCount: player.tracks.length,
                    itemBuilder: (context, index) {
                      final track = player.tracks[index];
                      final isPlaying = player.currentTrack?.id == track.id;
                      
                      return GestureDetector(
                        onTap: () => player.playTrack(track),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Album Art Square
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.librarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: QueryArtworkWidget(
                                  id: track.albumId ?? 0,
                                  type: ArtworkType.ALBUM,
                                  artworkBorder: BorderRadius.circular(8),
                                  nullArtworkWidget: const Center(
                                    child: Icon(Icons.music_note_rounded, color: AppColors.textMuted),
                                  ),
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
                                        color: isPlaying ? AppColors.libraryTextGreen : AppColors.white,
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
                              
                              // Options / More
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
