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
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor, // Very dark brown/black
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${player.queue.length} tracks lined up.',
                                style: AppTypography.body(
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.queue_music_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quick Picks',
                                  style: AppTypography.label(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
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
                        data: Theme.of(context).copyWith(),
                        child: RawScrollbar(
                          thumbColor: AppColors.pillPaleOrange,
                          thickness: 6,
                          radius: const Radius.circular(3),
                          interactive: true,
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              24,
                            ), // Bottom padding
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
                                key: ValueKey(
                                  track.id,
                                ), // Key MUST be at the top-level widget in ReorderableListView
                                onTap: () {
                                  if (!isPlaying) {
                                    player.playTrack(track);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? AppColors.playerOrange.withOpacity(
                                            0.15,
                                          )
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      if (!isPlaying) ...[
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            child: Icon(
                                              Icons.drag_indicator_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.4),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],

                                      // Album Art
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child:
                                            !track.isLocal &&
                                                track.albumArt.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: track.albumArt,
                                                fit: BoxFit.cover,
                                                fadeInDuration: Duration.zero,
                                                fadeOutDuration: Duration.zero,
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => Icon(
                                                      Icons.music_note,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.24),
                                                    ),
                                              )
                                            : QueryArtworkWidget(
                                                id: track.albumId ?? 0,
                                                type: ArtworkType.ALBUM,
                                                artworkBorder:
                                                    BorderRadius.zero,
                                                keepOldArtwork: true,
                                                nullArtworkWidget: Icon(
                                                  Icons.music_note,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.24),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Track Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              track.title,
                                              style: AppTypography.body(
                                                size: 16,
                                                weight: FontWeight.w600,
                                                color: isPlaying
                                                    ? AppColors.pillPaleOrange
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              track.artist,
                                              style: AppTypography.label(
                                                size: 13,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Overflow Menu
                                      Icon(
                                        Icons.more_vert_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
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
          ],
        ),
      ),
    );
  }
}
