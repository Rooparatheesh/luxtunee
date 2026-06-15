// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette - Warm Cream / Soft Stone (matches design)
  static const Color background = Color(0xFFE8E4DF);
  static const Color surface = Color(0xFFF0EDE8);
  static const Color surfaceVariant = Color(0xFFD8D3CC);
  static const Color card = Color(0xFFEAE6E1);

  // Dark / Ink
  static const Color ink = Color(0xFF1A1814);
  static const Color inkSecondary = Color(0xFF3D3A35);
  static const Color inkMuted = Color(0xFF7A7570);
  static const Color inkLight = Color(0xFFA8A39D);

  // Accent
  static const Color accent = Color(0xFF1A1814);
  static const Color accentGlow = Color(0xFF4A4540);

  // Semantic
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color selected = Color(0xFF1A1814);
  static const Color selectedFg = Color(0xFFFFFFFF);

  // Gradient stops
  static const List<Color> blobGradient = [
    Color(0xFFDDD8D0),
    Color(0xFFCCC7BF),
  ];
}

class AppTypography {
  static TextStyle display({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double letterSpacing = -0.5,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.3,
  );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.inkSecondary,
  }) => GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.inkMuted,
    double letterSpacing = 0.3,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light().copyWith(
      primary: AppColors.ink,
      secondary: AppColors.inkSecondary,
      surface: AppColors.surface,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.ink,
    ),
    canvasColor: AppColors.background,
    cardColor: AppColors.card,
    textTheme: TextTheme(
      displayLarge: AppTypography.display(size: 40),
      displayMedium: AppTypography.display(size: 32),
      headlineLarge: AppTypography.heading(size: 26),
      headlineMedium: AppTypography.heading(size: 22),
      headlineSmall: AppTypography.heading(size: 18),
      bodyLarge: AppTypography.body(size: 16),
      bodyMedium: AppTypography.body(size: 14),
      bodySmall: AppTypography.body(size: 12),
      labelLarge: AppTypography.label(size: 13),
      labelSmall: AppTypography.label(size: 10),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.heading(size: 16),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    dividerColor: AppColors.surfaceVariant,
    iconTheme: const IconThemeData(color: AppColors.ink),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
