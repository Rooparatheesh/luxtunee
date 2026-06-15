// lib/presentation/screens/player/player_screen.dart

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_theme.dart';
import 'dart:math' as math;

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final track = player.currentTrack;
        final progress = player.duration.inSeconds > 0
            ? player.position.inSeconds / player.duration.inSeconds
            : 0.0;

        return Scaffold(
          backgroundColor: AppColors.playerBackground,
          body: SafeArea(
            child: FadeTransition(
              opacity: _enterCtrl,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.white, size: 32),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Text(
                          'Now Playing',
                          style: AppTypography.heading(size: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded, color: AppColors.white, size: 28),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Polaroid Album Art
                  Transform.rotate(
                    angle: -0.05, // Slight tilt like the screenshot
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48), // Bottom padding for polaroid look
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(4, 10),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: track != null
                            ? QueryArtworkWidget(
                                id: track.albumId ?? 0,
                                type: ArtworkType.ALBUM,
                                artworkBorder: BorderRadius.zero,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: Container(
                                  color: AppColors.libraryBackground,
                                  child: const Center(
                                    child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.libraryBackground,
                                child: const Center(
                                  child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Title and Artist
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track?.title ?? 'No Track',
                                style: AppTypography.display(
                                  size: 24,
                                  weight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                track?.artist ?? '',
                                style: AppTypography.body(
                                  size: 14,
                                  color: AppColors.white.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorite ? AppColors.playerOrange : AppColors.white,
                            size: 28,
                          ),
                          onPressed: () => setState(() => _isFavorite = !_isFavorite),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seek Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: AppColors.playerOrange,
                        inactiveTrackColor: AppColors.white.withOpacity(0.3),
                        thumbColor: AppColors.playerOrange,
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (v) => player.seek(
                          Duration(seconds: (v * player.duration.inSeconds).round()),
                        ),
                      ),
                    ),
                  ),

                  // Timestamps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(player.position),
                          style: AppTypography.label(color: AppColors.white.withOpacity(0.6)),
                        ),
                        Text(
                          _fmt(player.duration),
                          style: AppTypography.label(color: AppColors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Playback Controls (Pills)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PillButton(
                          icon: Icons.skip_previous_rounded,
                          color: AppColors.pillPaleOrange,
                          onTap: () => player.skipPrev(),
                        ),
                        const SizedBox(width: 16),
                        _PillButton(
                          icon: player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: AppColors.pillPaleGreen,
                          isLarge: true,
                          onTap: () => player.togglePlayPause(),
                        ),
                        const SizedBox(width: 16),
                        _PillButton(
                          icon: Icons.skip_next_rounded,
                          color: AppColors.pillPaleOrange,
                          onTap: () => player.skipNext(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom Controls (Shuffle, Loop, etc.)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BottomIcon(icon: Icons.shuffle_rounded, onTap: () {}),
                        _BottomIcon(icon: Icons.repeat_rounded, onTap: () {}),
                        _BottomIcon(icon: Icons.queue_music_rounded, onTap: () {}),
                        _BottomIcon(icon: Icons.share_rounded, onTap: () {}),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLarge;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.color,
    this.isLarge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 80 : 64,
        height: isLarge ? 80 : 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: isLarge ? 36 : 28,
          color: AppColors.playerBackground, // Deep brown icon
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BottomIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.white.withOpacity(0.9),
        ),
      ),
    );
  }
}
