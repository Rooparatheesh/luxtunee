// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Library / Dark Theme
  static const Color libraryBackground = Color(0xFF181520); // Deep dark purple/grey
  static const Color librarySurface = Color(0xFF232030); 
  static const Color libraryPillBg = Color(0xFF485655); // Album/Artist dark pills
  static const Color libraryPillActiveBg = Color(0xFF55826A); // Greenish active pill
  static const Color libraryTextGreen = Color(0xFF89B99E); // "Library" text color

  // Now Playing / Earthy Theme
  static const Color playerBackground = Color(0xFF583311); // Deep brown
  static const Color playerOrange = Color(0xFFB45A17); // Orange accents
  static const Color playerMiniBg = Color(0xFF914E15); // Mini player brown

  // Controls (Pills)
  static const Color pillPaleOrange = Color(0xFFFFCC99);
  static const Color pillPaleGreen = Color(0xFFC1D4A6);

  // Common Semantic
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textMuted = Color(0xFF8A8498);
  static const Color textLight = Color(0xFFB5AFBF);

  static const Color bottomNavBg = Color(0xFF1E1B26);
}

class AppTypography {
  static TextStyle display({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.white,
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
    Color color = AppColors.white,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.3,
  );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textLight,
  }) => GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textMuted,
    double letterSpacing = 0.3,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.libraryBackground,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: AppColors.libraryTextGreen,
      secondary: AppColors.playerOrange,
      surface: AppColors.librarySurface,
      onPrimary: AppColors.libraryBackground,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
    ),
    canvasColor: AppColors.libraryBackground,
    cardColor: AppColors.librarySurface,
    textTheme: TextTheme(
      displayLarge: AppTypography.display(size: 40),
      displayMedium: AppTypography.display(size: 32),
      headlineLarge: AppTypography.heading(size: 26),
      headlineMedium: AppTypography.heading(size: 22),
      headlineSmall: AppTypography.heading(size: 18),
      bodyLarge: AppTypography.body(size: 16, color: AppColors.white),
      bodyMedium: AppTypography.body(size: 14),
      bodySmall: AppTypography.body(size: 12),
      labelLarge: AppTypography.label(size: 13),
      labelSmall: AppTypography.label(size: 10),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.libraryBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.heading(size: 16),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    dividerColor: AppColors.textMuted.withValues(alpha: 0.2),
    iconTheme: const IconThemeData(color: AppColors.white),

  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF0F0F5),
    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF4A7C59),
      secondary: const Color(0xFFE87A24),
      surface: const Color(0xFFFFFFFF),
      onPrimary: const Color(0xFFFFFFFF),
      onSecondary: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF1E1B26),
    ),
    canvasColor: const Color(0xFFF0F0F5),
    cardColor: const Color(0xFFFFFFFF),
    textTheme: TextTheme(
      displayLarge: AppTypography.display(size: 40, color: AppColors.black),
      displayMedium: AppTypography.display(size: 32, color: AppColors.black),
      headlineLarge: AppTypography.heading(size: 26, color: AppColors.black),
      headlineMedium: AppTypography.heading(size: 22, color: AppColors.black),
      headlineSmall: AppTypography.heading(size: 18, color: AppColors.black),
      bodyLarge: AppTypography.body(size: 16, color: AppColors.black),
      bodyMedium: AppTypography.body(size: 14, color: AppColors.textMuted),
      bodySmall: AppTypography.body(size: 12, color: AppColors.textMuted),
      labelLarge: AppTypography.label(size: 13, color: AppColors.textMuted),
      labelSmall: AppTypography.label(size: 10, color: AppColors.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF0F0F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.heading(size: 16, color: AppColors.black),
      iconTheme: const IconThemeData(color: AppColors.black),
    ),
    dividerColor: AppColors.textMuted.withValues(alpha: 0.2),
    iconTheme: const IconThemeData(color: AppColors.black),

  );
}
