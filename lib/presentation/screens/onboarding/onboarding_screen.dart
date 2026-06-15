// lib/presentation/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:luxtunee/theme/app_theme.dart';
import 'package:luxtunee/presentation/widgets/common/blob_painter.dart';
import '../../../core/constants/app_constants.dart';
import '../main_scaffold.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _enterCtrl;
  late Animation<Offset> _img1;
  late Animation<Offset> _img2;
  late Animation<Offset> _img3;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _btnFade;

  static const _singer1 = 'assets/images/yesu.jpg';
  static const _singer2 = 'assets/images/sithrs.jpg';
  static const _singer3 = 'assets/images/ks.jpg';

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _img1 = Tween<Offset>(begin: const Offset(-0.5, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
          ),
        );

    _img2 = Tween<Offset>(begin: const Offset(0.5, -0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
          ),
        );

    _img3 = Tween<Offset>(begin: const Offset(0.3, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
          ),
        );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
          ),
        );

    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _navigateToArtistSelect() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScaffold(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.libraryBackground,
      body: Stack(
        children: [
          // Decorative blob outlines in background
          Positioned(
            top: size.height * 0.05,
            left: -40,
            child: _BlobOutline(size: 200, opacity: 0.15),
          ),
          Positioned(
            top: size.height * 0.25,
            right: -30,
            child: _BlobOutline(size: 160, opacity: 0.1),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LuxTune',
                        style: AppTypography.display(
                          size: 26,
                          weight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToArtistSelect,
                        child: Text(
                          'Skip',
                          style: AppTypography.body(
                            size: 15,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Floating artist images
                  Expanded(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_enterCtrl, _floatCtrl]),
                      builder: (_, __) => Stack(
                        children: [
                          // Blob lines decoration
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              size: Size(size.width - 48, size.height * 0.55),
                              painter: _BlobLinePainter(
                                animValue: _floatCtrl.value,
                              ),
                            ),
                          ),

                          // Singer 1 — top left
                          Positioned(
                            top:
                                20 +
                                math.sin(_floatCtrl.value * 2 * math.pi) * 8,
                            left: 0,
                            child: SlideTransition(
                              position: _img1,
                              child: _FloatingArtistImage(
                                imageUrl: _singer1,
                                size: 130,
                              ),
                            ),
                          ),

                          // Singer 2 — top right, star blob
                          Positioned(
                            top:
                                0 +
                                math.sin(_floatCtrl.value * 2 * math.pi + 1) *
                                    10,
                            right: 20,
                            child: SlideTransition(
                              position: _img2,
                              child: _FloatingArtistImage(
                                imageUrl: _singer2,
                                size: 140,
                                isPointed: true,
                              ),
                            ),
                          ),

                          // Singer 3 — bottom right
                          Positioned(
                            bottom:
                                40 +
                                math.sin(_floatCtrl.value * 2 * math.pi + 2) *
                                    6,
                            right: 0,
                            child: SlideTransition(
                              position: _img3,
                              child: _FloatingArtistImage(
                                imageUrl: _singer3,
                                size: 150,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Text content
                  AnimatedBuilder(
                    animation: _enterCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Elevate ',
                                style: AppTypography.display(
                                  size: 36,
                                  weight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              TextSpan(
                                text: 'Every\nMoment With ',
                                style: AppTypography.display(
                                  size: 36,
                                  weight: FontWeight.w400,
                                  letterSpacing: -1,
                                ),
                              ),
                              TextSpan(
                                text: 'Music',
                                style: AppTypography.display(
                                  size: 36,
                                  weight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Immerse Yourself In A World Where Every Beat\nEnhances Your Mood And Every Melody Tells\nYour Story.',
                          style: AppTypography.body(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CTA Buttons
                  AnimatedBuilder(
                    animation: _enterCtrl,
                    builder: (_, child) =>
                        FadeTransition(opacity: _btnFade, child: child),
                    child: Column(
                      children: [
                        // Get Started button
                        _LuxButton(
                          label: 'Get Started',
                          onTap: _navigateToArtistSelect,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────
// Email / primary CTA button
// ─────────────────────────────────────────────

class _LuxButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _LuxButton({required this.label, required this.onTap});

  @override
  State<_LuxButton> createState() => _LuxButtonState();
}

class _LuxButtonState extends State<_LuxButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.libraryPillActiveBg,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.body(
                size: 16,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Decorative blob widgets (unchanged)
// ─────────────────────────────────────────────

class _FloatingArtistImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isPointed;

  const _FloatingArtistImage({
    required this.imageUrl,
    required this.size,
    this.isPointed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isPointed)
            CustomPaint(
              size: Size(size, size),
              painter: _StarBlobPainter(color: AppColors.librarySurface),
            )
          else
            AnimatedBlob(color: AppColors.librarySurface, size: size),
          ClipOval(
            child: Image.asset(
              imageUrl,
              width: size * 0.75,
              height: size * 0.75,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size * 0.75,
                height: size * 0.75,
                color: AppColors.librarySurface,
                child: const Icon(Icons.person),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobOutline extends StatelessWidget {
  final double size;
  final double opacity;

  const _BlobOutline({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size),
        painter: _BlobOutlinePainter(),
      ),
    );
  }
}

class _BlobOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.85;
    const points = 8;
    final path = Path();
    List<Offset> pts = [];
    for (int i = 0; i < points; i++) {
      final angle = (2 * math.pi / points) * i - math.pi / 2;
      final noise = math.sin(i * 1.3) * 0.18 + 1.0;
      final radius = r * noise;
      pts.add(
        Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
      );
    }
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length; i++) {
      final next = pts[(i + 1) % pts.length];
      final curr = pts[i];
      path.quadraticBezierTo(
        curr.dx,
        curr.dy,
        (curr.dx + next.dx) / 2,
        (curr.dy + next.dy) / 2,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BlobLinePainter extends CustomPainter {
  final double animValue;
  _BlobLinePainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int j = 0; j < 3; j++) {
      final cx = size.width * (0.25 + j * 0.25);
      final cy = size.height * (0.3 + j * 0.15);
      final r = 80.0 + j * 20;
      final path = Path();
      const points = 8;
      List<Offset> pts = [];
      for (int i = 0; i < points; i++) {
        final angle = (2 * math.pi / points) * i;
        final noise =
            math.sin(animValue * 2 * math.pi + i * 1.3 + j) * 0.15 + 1.0;
        pts.add(
          Offset(
            cx + r * noise * math.cos(angle),
            cy + r * noise * math.sin(angle),
          ),
        );
      }
      path.moveTo(pts[0].dx, pts[0].dy);
      for (int i = 0; i < pts.length; i++) {
        final next = pts[(i + 1) % pts.length];
        final curr = pts[i];
        path.quadraticBezierTo(
          curr.dx,
          curr.dy,
          (curr.dx + next.dx) / 2,
          (curr.dy + next.dy) / 2,
        );
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobLinePainter old) => old.animValue != animValue;
}

class _StarBlobPainter extends CustomPainter {
  final Color color;
  _StarBlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) * 0.9;
    final innerR = outerR * 0.55;
    const spikes = 6;
    final path = Path();
    for (int i = 0; i < spikes * 2; i++) {
      final angle = (math.pi / spikes) * i - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
