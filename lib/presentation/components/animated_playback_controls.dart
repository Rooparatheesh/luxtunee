import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum PlaybackButton { none, prev, playPause, next }

class AnimatedPlaybackControls extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  const AnimatedPlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  State<AnimatedPlaybackControls> createState() =>
      _AnimatedPlaybackControlsState();
}

class _AnimatedPlaybackControlsState extends State<AnimatedPlaybackControls> {
  PlaybackButton _lastClicked = PlaybackButton.none;

  // Handles the expansion flow and resets after a delay
  void _handleTap(PlaybackButton button, VoidCallback action) {
    setState(() {
      _lastClicked = button;
    });

    // Trigger the actual action slightly delayed to let the user feel the animation
    Future.delayed(const Duration(milliseconds: 150), action);

    // Return to the idle (1.0 weight) state
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _lastClicked = PlaybackButton.none);
    });
  }

  // The exact weights used in the PixelPlayer Kotlin code
  double _getWeight(PlaybackButton button) {
    if (_lastClicked == PlaybackButton.none) return 1.0; // Base weight
    if (_lastClicked == button) return 1.1; // Expansion weight
    return 0.65; // Compression weight
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90, // Match the height from PixelPlayer
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate dynamic widths based on the active weight flow
          final totalWeight =
              _getWeight(PlaybackButton.prev) +
              _getWeight(PlaybackButton.playPause) +
              _getWeight(PlaybackButton.next);

          final gapSpace = 16.0; // 8px gap * 2
          final availableWidth = constraints.maxWidth - gapSpace;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildButton(
                width:
                    availableWidth *
                    (_getWeight(PlaybackButton.prev) / totalWeight),
                icon: Icons.skip_previous_rounded,
                color: AppColors.pillPaleOrange,
                isPlayPause: false,
                onTap: () => _handleTap(PlaybackButton.prev, widget.onPrevious),
              ),
              _buildButton(
                width:
                    availableWidth *
                    (_getWeight(PlaybackButton.playPause) / totalWeight),
                icon: widget.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppColors.pillPaleGreen,
                isPlayPause: true,
                onTap: () =>
                    _handleTap(PlaybackButton.playPause, widget.onPlayPause),
              ),
              _buildButton(
                width:
                    availableWidth *
                    (_getWeight(PlaybackButton.next) / totalWeight),
                icon: Icons.skip_next_rounded,
                color: AppColors.pillPaleOrange,
                isPlayPause: false,
                onTap: () => _handleTap(PlaybackButton.next, widget.onNext),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton({
    required double width,
    required IconData icon,
    required Color color,
    required bool isPlayPause,
    required VoidCallback onTap,
  }) {
    // The exact shape morphing logic from PixelPlayer
    final borderRadius = isPlayPause
        ? (widget.isPlaying
              ? 26.0
              : 60.0) // Squircle when playing, Circle when paused
        : 60.0; // Next/Prev are always circular

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn, // The Material 3 standard curve
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(
              icon,
              key: ValueKey(icon),
              size: 36,
              color: AppColors
                  .playerBackground, // Deep brown/black icon to match theme
            ),
          ),
        ),
      ),
    );
  }
}
