// lib/presentation/widgets/common/blob_painter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

List<Offset> blobPoints({
  required double cx,
  required double cy,
  required double baseRadius,
  required double animValue,
  int seed = 0,
  int numPoints = 8,
}) {
  final pts = <Offset>[];
  for (int i = 0; i < numPoints; i++) {
    final angle = (2 * math.pi / numPoints) * i - math.pi / 2;
    final n1 = math.sin(animValue * 1.0 + i * 1.57 + seed * 0.7) * 0.22;
    final n2 = math.cos(animValue * 0.7 + i * 2.20 + seed * 1.3) * 0.14;
    final r = baseRadius * (1.0 + n1 + n2);
    pts.add(Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)));
  }
  return pts;
}

Path buildBlobPath(List<Offset> pts) {
  final path = Path();
  final n = pts.length;
  final start = Offset(
    (pts[n - 1].dx + pts[0].dx) / 2,
    (pts[n - 1].dy + pts[0].dy) / 2,
  );
  path.moveTo(start.dx, start.dy);
  for (int i = 0; i < n; i++) {
    final curr = pts[i];
    final next = pts[(i + 1) % n];
    final mid = Offset((curr.dx + next.dx) / 2, (curr.dy + next.dy) / 2);
    path.quadraticBezierTo(curr.dx, curr.dy, mid.dx, mid.dy);
  }
  path.close();
  return path;
}

Offset blobEdgeAtProgress({
  required double progress,
  required double cx,
  required double cy,
  required double baseRadius,
  required double animValue,
  int seed = 0,
  int numPoints = 8,
  int samples = 300,
}) {
  final pts = blobPoints(
    cx: cx,
    cy: cy,
    baseRadius: baseRadius,
    animValue: animValue,
    seed: seed,
    numPoints: numPoints,
  );
  final n = pts.length;

  final sampled = <Offset>[];
  for (int s = 0; s < samples; s++) {
    final t = s / samples;
    final rawIdx = t * n;
    final i0 = rawIdx.floor() % n;
    final i1 = (i0 + 1) % n;
    final lt = rawIdx - rawIdx.floor();

    final prev = pts[(i0 - 1 + n) % n];
    final curr = pts[i0];
    final next = pts[i1];

    final cp = curr;
    final midStart = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
    final midEnd = Offset((curr.dx + next.dx) / 2, (curr.dy + next.dy) / 2);

    final qt = lt;
    final bx =
        (1 - qt) * (1 - qt) * midStart.dx +
        2 * (1 - qt) * qt * cp.dx +
        qt * qt * midEnd.dx;
    final by =
        (1 - qt) * (1 - qt) * midStart.dy +
        2 * (1 - qt) * qt * cp.dy +
        qt * qt * midEnd.dy;
    sampled.add(Offset(bx, by));
  }

  final idx = (progress * samples).floor() % samples;
  return sampled[idx];
}

class BlobPainter extends CustomPainter {
  final Color color;
  final double animValue;
  final int seed;
  final Color? strokeColor;
  final double strokeWidth;

  BlobPainter({
    required this.color,
    this.animValue = 0,
    this.seed = 0,
    this.strokeColor,
    this.strokeWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.88;
    final pts = blobPoints(
      cx: cx,
      cy: cy,
      baseRadius: r,
      animValue: animValue,
      seed: seed,
    );
    final path = buildBlobPath(pts);
    canvas.drawPath(path, Paint()..color = color);
    if (strokeColor != null && strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(BlobPainter old) =>
      old.animValue != animValue || old.color != color;
}

class BlobClipper extends CustomClipper<Path> {
  final double animValue;
  final int seed;
  const BlobClipper({required this.animValue, this.seed = 0});

  @override
  Path getClip(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.88;
    final pts = blobPoints(
      cx: cx,
      cy: cy,
      baseRadius: r,
      animValue: animValue,
      seed: seed,
    );
    return buildBlobPath(pts);
  }

  @override
  bool shouldReclip(BlobClipper old) => old.animValue != animValue;
}

class BlobProgressPainter extends CustomPainter {
  final double animValue;
  final double progress;
  final int seed;
  final double dotSize;
  final Color dotColor;
  final Color playedColor;
  final Color ghostColor;
  final double strokeWidth;

  static const int _samples = 360;

  BlobProgressPainter({
    required this.animValue,
    required this.progress,
    this.seed = 0,
    this.dotSize = 16,
    this.dotColor = Colors.black,
    this.playedColor = const Color(0xFF1A1814),
    this.ghostColor = const Color(0x40000000),
    this.strokeWidth = 2.0,
  });

  List<Offset> _sampleBlob(double cx, double cy, double r) {
    final pts = blobPoints(
      cx: cx,
      cy: cy,
      baseRadius: r,
      animValue: animValue,
      seed: seed,
    );
    final n = pts.length;
    final sampled = <Offset>[];
    for (int s = 0; s < _samples; s++) {
      final t = s / _samples;
      final rawIdx = t * n;
      final i0 = rawIdx.floor() % n;
      final prev = pts[(i0 - 1 + n) % n];
      final curr = pts[i0];
      final next = pts[(i0 + 1) % n];
      final lt = rawIdx - rawIdx.floor();
      final midStart = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      final midEnd = Offset((curr.dx + next.dx) / 2, (curr.dy + next.dy) / 2);
      final qt = lt;
      final bx =
          (1 - qt) * (1 - qt) * midStart.dx +
          2 * (1 - qt) * qt * curr.dx +
          qt * qt * midEnd.dx;
      final by =
          (1 - qt) * (1 - qt) * midStart.dy +
          2 * (1 - qt) * qt * curr.dy +
          qt * qt * midEnd.dy;
      sampled.add(Offset(bx, by));
    }
    return sampled;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.88;

    final sampled = _sampleBlob(cx, cy, r);
    final total = sampled.length;
    final splitIdx = (progress * total).round().clamp(0, total);

    final ghostPaint = Paint()
      ..color = ghostColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final playedPaint = Paint()
      ..color = playedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ghost: remaining path
    if (splitIdx < total - 1) {
      final ghostPath = Path();
      ghostPath.moveTo(sampled[splitIdx].dx, sampled[splitIdx].dy);
      for (int i = splitIdx + 1; i < total; i++) {
        ghostPath.lineTo(sampled[i].dx, sampled[i].dy);
      }
      ghostPath.lineTo(sampled[0].dx, sampled[0].dy);
      canvas.drawPath(ghostPath, ghostPaint);
    }

    // Played: 0 → splitIdx
    if (splitIdx > 1) {
      final playedPath = Path();
      playedPath.moveTo(sampled[0].dx, sampled[0].dy);
      for (int i = 1; i <= splitIdx && i < total; i++) {
        playedPath.lineTo(sampled[i].dx, sampled[i].dy);
      }
      canvas.drawPath(playedPath, playedPaint);
    }

    // Dot at progress point
    final dotIdx = splitIdx.clamp(0, total - 1);
    final dotPos = sampled[dotIdx];
    final half = dotSize / 2;

    // Outer glow
    canvas.drawCircle(
      dotPos,
      half + 3,
      Paint()..color = Colors.black.withOpacity(0.10),
    );
    // Shadow ring
    canvas.drawCircle(
      dotPos,
      half + 1,
      Paint()..color = Colors.black.withOpacity(0.20),
    );
    // Dot fill
    canvas.drawCircle(dotPos, half, Paint()..color = dotColor);
    // White center highlight
    canvas.drawCircle(
      Offset(dotPos.dx - half * 0.2, dotPos.dy - half * 0.2),
      half * 0.28,
      Paint()..color = Colors.white.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(BlobProgressPainter old) =>
      old.animValue != animValue || old.progress != progress;
}

class AnimatedBlobWithDot extends StatefulWidget {
  final double size;
  final Color blobColor;
  final Widget? child;
  final double progress;
  final int seed;
  final double dotSize;
  final Color dotColor;
  final Color strokeColor;
  final double strokeWidth;

  const AnimatedBlobWithDot({
    super.key,
    required this.size,
    required this.blobColor,
    this.child,
    this.progress = 0,
    this.seed = 1,
    this.dotSize = 16,
    this.dotColor = Colors.black,
    this.strokeColor = const Color(0x40000000),
    this.strokeWidth = 2.0,
  });

  @override
  State<AnimatedBlobWithDot> createState() => _AnimatedBlobWithDotState();
}

class _AnimatedBlobWithDotState extends State<AnimatedBlobWithDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final animVal = _ctrl.value * 2 * math.pi;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Blob fill + clipped image
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: BlobPainter(
                  color: widget.blobColor,
                  animValue: animVal,
                  seed: widget.seed,
                ),
                child: widget.child != null
                    ? ClipPath(
                        clipper: BlobClipper(
                          animValue: animVal,
                          seed: widget.seed,
                        ),
                        child: SizedBox(
                          width: widget.size,
                          height: widget.size,
                          child: widget.child,
                        ),
                      )
                    : null,
              ),

              // Progress outline + dot
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: BlobProgressPainter(
                  animValue: animVal,
                  progress: widget.progress,
                  seed: widget.seed,
                  dotSize: widget.dotSize,
                  dotColor: widget.dotColor,
                  playedColor: widget.dotColor,
                  ghostColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Widget? child;
  final int seed;

  const AnimatedBlob({
    super.key,
    required this.color,
    required this.size,
    this.child,
    this.seed = 0,
  });

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final animVal = _ctrl.value * 2 * math.pi;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: BlobPainter(
              color: widget.color,
              animValue: animVal,
              seed: widget.seed,
            ),
            child: ClipPath(
              clipper: BlobClipper(animValue: animVal, seed: widget.seed),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
