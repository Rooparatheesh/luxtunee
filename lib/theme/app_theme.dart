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
      centerTitle: true,
      titleTextStyle: AppTypography.heading(size: 16),
      iconTheme: const IconThemeData(color: AppColors.white),
    ),
    dividerColor: AppColors.textMuted.withOpacity(0.2),
    iconTheme: const IconThemeData(color: AppColors.white),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
