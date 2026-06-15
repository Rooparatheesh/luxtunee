// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'LuxTune';
  static const String appVersion = '1.0.0';

  // Animation Durations
  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration normalAnim = Duration(milliseconds: 350);
  static const Duration slowAnim = Duration(milliseconds: 600);
  static const Duration pageAnim = Duration(milliseconds: 450);

  // Player
  static const double playerSheetMinHeight = 80.0;
  static const double playerSheetMaxHeight = 1.0; // fraction

  // Grid
  static const int artistGridCrossAxisCount = 3;
  static const double artistAvatarSize = 90.0;

  // Border Radius
  static const double radiusXS = 8.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 20.0;
  static const double radiusLG = 32.0;
  static const double radiusXL = 48.0;
  static const double radiusFull = 999.0;

  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
}
