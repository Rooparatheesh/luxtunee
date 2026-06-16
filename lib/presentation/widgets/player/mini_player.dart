// lib/presentation/widgets/player/mini_player.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';
import '../../screens/player/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.currentTrack == null) return const SizedBox.shrink();

        final track = player.currentTrack!;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const PlayerScreen(),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.playerMiniBg,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular Album Art
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: !track.isLocal && track.albumArt.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: track.albumArt,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) => Container(
                            color: AppColors.libraryBackground,
                            child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.libraryBackground,
                            child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                          ),
                        )
                      : QueryArtworkWidget(
                          id: track.albumId ?? 0,
                          type: ArtworkType.ALBUM,
                          keepOldArtwork: true,
                          nullArtworkWidget: Container(
                            color: AppColors.libraryBackground,
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                
                // Track Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        style: AppTypography.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: AppTypography.label(
                          size: 11,
                          color: AppColors.white.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => player.togglePlayPause(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.transparent, // Ensure gesture area
                        child: Icon(
                          player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => player.skipNext(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.transparent, // Ensure gesture area
                        child: const Icon(Icons.skip_next_rounded, color: AppColors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
