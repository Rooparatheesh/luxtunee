import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavyMusicSlider extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final bool isPlaying;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final Color inactiveColor;

  const WavyMusicSlider({
    super.key,
    required this.value,
    required this.isPlaying,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<WavyMusicSlider> createState() => _WavyMusicSliderState();
}

class _WavyMusicSliderState extends State<WavyMusicSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(WavyMusicSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _waveController.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final clampedX = localPos.dx.clamp(0.0, box.size.width);
        widget.onChanged(clampedX / box.size.width);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.globalPosition);
        final clampedX = localPos.dx.clamp(0.0, box.size.width);
        widget.onChanged(clampedX / box.size.width);
      },
      child: SizedBox(
        height: 36, // Tap target height
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            // We pass the controller value to shift the phase
            return CustomPaint(
              painter: _WavySliderPainter(
                progress: widget.value,
                phase: _waveController.value * 2 * math.pi,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
                isSquiggly: widget.isPlaying,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavySliderPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color activeColor;
  final Color inactiveColor;
  final bool isSquiggly;

  _WavySliderPainter({
    required this.progress,
    required this.phase,
    required this.activeColor,
    required this.inactiveColor,
    required this.isSquiggly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final activeWidth = size.width * progress;

    // Paint for inactive straight line
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Paint for active wavy line
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw inactive track (straight line from thumb to end)
    canvas.drawLine(
      Offset(activeWidth, centerY),
      Offset(size.width, centerY),
      inactivePaint,
    );

    final path = Path();

    if (isSquiggly) {
      final frequency = 30.0; // Wavelength in pixels
      final amplitude = 4.0; // Height of wave

      // Move exactly to the first calculated wave point to avoid a vertical line glitch
      final startY = centerY + math.sin(phase) * amplitude;
      path.moveTo(0, startY);

      for (double x = 1.0; x <= activeWidth; x += 1.0) {
        // Shift phase forward so the wave flows to the left (backwards)
        final y =
            centerY +
            math.sin((x / frequency) * math.pi * 2 + phase) * amplitude;
        path.lineTo(x, y);
      }
    } else {
      path.moveTo(0, centerY);
      path.lineTo(activeWidth, centerY);
    }

    canvas.drawPath(path, activePaint);

    // Draw thumb at the end of the wave
    final thumbPaint = Paint()..color = activeColor;
    final thumbY = isSquiggly
        ? centerY + math.sin((activeWidth / 30.0) * math.pi * 2 + phase) * 4.0
        : centerY;

    canvas.drawCircle(Offset(activeWidth, thumbY), 8.0, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WavySliderPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        phase != oldDelegate.phase ||
        isSquiggly != oldDelegate.isSquiggly;
  }
}
