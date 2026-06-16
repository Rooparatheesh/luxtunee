import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';

class QueueBottomSheet extends StatefulWidget {
  const QueueBottomSheet({super.key});

  @override
  State<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends State<QueueBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.playerBackground, // Very dark brown/black
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // 2. Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Consumer<PlayerProvider>(
                        builder: (context, player, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next up',
                                style: AppTypography.display(
                                  size: 32,
                                  weight: FontWeight.w800,
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${player.queue.length} tracks lined up.',
                                style: AppTypography.body(
                                  size: 14,
                                  color: AppColors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.pillPaleOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.all_inclusive_rounded, color: AppColors.pillPaleOrange, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.queue_music_rounded, color: AppColors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Picks',
                                  style: AppTypography.label(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 3. The Reorderable List
                Expanded(
                  child: Consumer<PlayerProvider>(
                    builder: (context, player, _) {
                      final currentTrack = player.currentTrack;
                      final queue = player.queue;
                      
                      return Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent, // Prevents white background when dragging
                        ),
                        child: RawScrollbar(
                          thumbColor: AppColors.pillPaleOrange,
                          thickness: 6,
                          radius: const Radius.circular(3),
                          interactive: true,
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Bottom padding for floating controls
                            itemCount: queue.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = player.queue.removeAt(oldIndex);
                              player.queue.insert(newIndex, item);
                              player.notifyListeners(); // Force update
                            },
                            itemBuilder: (context, index) {
                              final track = queue[index];
                              final isPlaying = currentTrack?.id == track.id;
                              
                              return GestureDetector(
                                key: ValueKey(track.id), // Key MUST be at the top-level widget in ReorderableListView
                                onTap: () {
                                  if (!isPlaying) {
                                    player.playTrack(track);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isPlaying ? AppColors.playerOrange.withOpacity(0.15) : AppColors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      if (!isPlaying) ...[
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Icon(Icons.drag_indicator_rounded, color: AppColors.white.withOpacity(0.4), size: 20),
                                          ),
                                        ),
                                      ],
                                      
                                      // Album Art
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: !track.isLocal && track.albumArt.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: track.albumArt,
                                                fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white24),
                                              )
                                            : QueryArtworkWidget(
                                                id: track.albumId ?? 0,
                                                type: ArtworkType.ALBUM,
                                                nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white24),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Track Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              track.title,
                                              style: AppTypography.body(
                                                size: 16,
                                                weight: FontWeight.w600,
                                                color: isPlaying ? AppColors.pillPaleOrange : AppColors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              track.artist,
                                              style: AppTypography.label(
                                                size: 13,
                                                color: AppColors.white.withOpacity(0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Overflow Menu
                                      Icon(Icons.more_vert_rounded, color: AppColors.white.withOpacity(0.6)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // 4. Floating Bottom Controls
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.1), // Slightly transparent dark brown
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFloatingIcon(Icons.shuffle_rounded, AppColors.pillPaleOrange, AppColors.playerBackground),
                    _buildFloatingIcon(Icons.repeat_one_rounded, AppColors.pillPaleOrange, AppColors.playerBackground),
                    _buildFloatingIcon(Icons.timer_rounded, Colors.transparent, AppColors.white),
                    _buildFloatingIcon(Icons.more_horiz_rounded, AppColors.libraryTextGreen.withOpacity(0.4), AppColors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor == Colors.transparent ? AppColors.white.withOpacity(0.05) : bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}
