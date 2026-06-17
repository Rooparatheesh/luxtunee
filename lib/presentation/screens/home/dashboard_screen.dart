import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../theme/app_theme.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/explore_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final explore = context.read<ExploreProvider>();
      if (explore.trendingTracks.isEmpty) {
        explore.fetchTrending();
      }
      final player = context.read<PlayerProvider>();
      if (player.tracks.isEmpty && !player.isLoading) {
        player.loadLibrary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Good Morning',
                style: AppTypography.display(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to LuxTune',
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Online Songs
                      _buildSectionTitle('Online Trending'),
                      const SizedBox(height: 16),
                      Consumer<ExploreProvider>(
                        builder: (context, explore, _) {
                          if (explore.isLoading) {
                            return const SizedBox(
                              height: 160, 
                              child: Center(child: CircularProgressIndicator(color: AppColors.libraryTextGreen))
                            );
                          }
                          if (explore.trendingTracks.isEmpty) {
                            return const SizedBox(height: 160, child: Center(child: Text('No online tracks', style: TextStyle(color: Colors.white))));
                          }
                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: explore.trendingTracks.length,
                              itemBuilder: (context, index) {
                                final track = explore.trendingTracks[index];
                                return GestureDetector(
                                  onTap: () {
                                    context.read<PlayerProvider>().playTrack(
                                      track,
                                      urlResolver: explore.getAudioUrl,
                                      newQueue: explore.trendingTracks,
                                    );
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: AppColors.librarySurface,
                                            borderRadius: BorderRadius.circular(16),
                                            image: track.albumArt.isNotEmpty
                                                ? DecorationImage(
                                                    image: CachedNetworkImageProvider(track.albumArt),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: track.albumArt.isEmpty
                                              ? const Center(child: Icon(Icons.music_note_rounded, size: 48, color: AppColors.textMuted))
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          track.title,
                                          style: AppTypography.body(color: AppColors.white, weight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Offline Songs
                      _buildSectionTitle('Local Offline Music'),
                      const SizedBox(height: 16),
                      Consumer<PlayerProvider>(
                        builder: (context, player, _) {
                          if (player.isLoading) {
                            return const SizedBox(
                              height: 160, 
                              child: Center(child: CircularProgressIndicator(color: AppColors.libraryTextGreen))
                            );
                          }
                          if (player.tracks.isEmpty) {
                            return const SizedBox(height: 160, child: Center(child: Text('No offline tracks found', style: TextStyle(color: Colors.white))));
                          }
                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: player.tracks.length,
                              itemBuilder: (context, index) {
                                final track = player.tracks[index];
                                return GestureDetector(
                                  onTap: () => player.playTrack(
                                    track,
                                    newQueue: player.tracks,
                                  ),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: AppColors.librarySurface,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: QueryArtworkWidget(
                                              id: track.albumId ?? 0,
                                              type: ArtworkType.ALBUM,
                                              artworkBorder: BorderRadius.zero,
                                              keepOldArtwork: true,
                                              artworkFit: BoxFit.cover,
                                              nullArtworkWidget: const Center(
                                                child: Icon(Icons.music_note_rounded, color: AppColors.textMuted, size: 48),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          track.title,
                                          style: AppTypography.body(color: AppColors.white, weight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Favorite Songs
                      _buildSectionTitle('Your Favorites'),
                      const SizedBox(height: 16),
                      Consumer<PlayerProvider>(
                        builder: (context, player, _) {
                          if (player.favoriteTracks.isEmpty) {
                            return const SizedBox(
                              height: 160, 
                              child: Center(
                                child: Text('No favorite tracks yet', style: TextStyle(color: Colors.white70))
                              )
                            );
                          }
                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: player.favoriteTracks.length,
                              itemBuilder: (context, index) {
                                final track = player.favoriteTracks[index];
                                return GestureDetector(
                                  onTap: () => player.playTrack(
                                    track,
                                    newQueue: player.favoriteTracks,
                                  ),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: AppColors.librarySurface,
                                            borderRadius: BorderRadius.circular(16),
                                            image: track.albumArt.isNotEmpty
                                                ? DecorationImage(
                                                    image: CachedNetworkImageProvider(track.albumArt),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: track.albumArt.isEmpty
                                              ? (track.isLocal ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: QueryArtworkWidget(
                                                    id: track.albumId ?? 0,
                                                    type: ArtworkType.ALBUM,
                                                    artworkBorder: BorderRadius.zero,
                                                    keepOldArtwork: true,
                                                    artworkFit: BoxFit.cover,
                                                    nullArtworkWidget: const Center(
                                                      child: Icon(Icons.music_note_rounded, color: AppColors.textMuted, size: 48),
                                                    ),
                                                  ),
                                                ) : const Center(child: Icon(Icons.music_note_rounded, color: AppColors.textMuted, size: 48)))
                                              : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          track.title,
                                          style: AppTypography.body(color: AppColors.white, weight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100), // padding for miniplayer
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.display(
        size: 20,
        weight: FontWeight.w600,
        color: AppColors.white,
      ),
    );
  }
}
