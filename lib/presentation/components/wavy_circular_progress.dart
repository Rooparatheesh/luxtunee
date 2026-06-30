import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavyCircularProgressIndicator extends StatefulWidget {
  final double? value;
  final double strokeWidth;
  final Color backgroundColor;
  final Color color;
  final Color wavyColor;

  const WavyCircularProgressIndicator({
    Key? key,
    this.value,
    this.strokeWidth = 4.0,
    required this.backgroundColor,
    required this.color,
    required this.wavyColor,
  }) : super(key: key);

  @override
  State<WavyCircularProgressIndicator> createState() =>
      _WavyCircularProgressIndicatorState();
}

class _WavyCircularProgressIndicatorState
    extends State<WavyCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavyCircularPainter(
            progress: widget.value,
            strokeWidth: widget.strokeWidth,
            backgroundColor: widget.backgroundColor,
            color: widget.color,
            wavyColor: widget.wavyColor,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class _WavyCircularPainter extends CustomPainter {
  final double? progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color color;
  final Color wavyColor;
  final double animationValue;

  _WavyCircularPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.color,
    required this.wavyColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final wavyPaint = Paint()
      ..color = wavyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;

    // Draw background circle
    canvas.drawCircle(center, radius, bgPaint);

    final actualProgress = progress ?? 0.0;

    if (progress == null) {
      // Indeterminate mode: spin a wavy line around
      _drawWavyArc(
        canvas,
        center,
        radius,
        animationValue * 2 * math.pi,
        math.pi / 1.5, // 120 degrees arc
        wavyPaint,
        animationValue,
      );
    } else {
      // Determinate mode
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * actualProgress;

      // Draw solid progress arc
      if (actualProgress > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          fgPaint,
        );
      }

      // Draw wavy head at the leading edge
      if (actualProgress < 1.0) {
        // Space available for wavy line
        final remainingAngle = 2 * math.pi - sweepAngle;
        // Wavy line covers 45 degrees, or whatever is remaining if less
        final wavySweep = math.min(math.pi / 4, remainingAngle);

        _drawWavyArc(
          canvas,
          center,
          radius,
          startAngle + sweepAngle,
          wavySweep,
          wavyPaint,
          -animationValue, // negative to animate forward
        );
      }
    }
  }

  void _drawWavyArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    Paint paint,
    double phase,
  ) {
    if (sweepAngle <= 0) return;

    final path = Path();
    final int segments = 30;
    final double amplitude = 3.5; // Height of the waves

    // Calculate how many waves based on the arc length
    final double arcLength = radius * sweepAngle;
    final double wavesCount = math.max(1, (arcLength / 20.0).roundToDouble());

    for (int i = 0; i <= segments; i++) {
      final double t = i / segments; // 0.0 to 1.0
      final double angle = startAngle + sweepAngle * t;

      // Calculate wave offset, smoothly tapering at the ends
      final double taper = math.sin(t * math.pi); // 0 at ends, 1 in middle
      final waveOffset =
          math.sin((t * wavesCount * 2 * math.pi) + (phase * 2 * math.pi)) *
          amplitude *
          taper;

      final double r = radius + waveOffset;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyCircularPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.wavyColor != wavyColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
