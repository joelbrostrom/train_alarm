import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF0A1628);
  static const navyLight = Color(0xFF132038);
  static const navySurface = Color(0xFF1A2940);
  static const cyan = Color(0xFF00E5FF);
  static const cyanDim = Color(0xFF00B8D4);
  static const skyBlue = Color(0xFF64B5F6);
  static const coral = Color(0xFFFF6B6B);
  static const amber = Color(0xFFFFB74D);
  static const mist = Color(0xFFE0E6ED);
  static const mistDim = Color(0xFF8899AA);
  static const white = Color(0xFFFFFFFF);
  static const glass = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
}

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.navy,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      onPrimary: AppColors.navy,
      secondary: AppColors.skyBlue,
      onSecondary: AppColors.navy,
      surface: AppColors.navySurface,
      onSurface: AppColors.mist,
      error: AppColors.coral,
      onError: AppColors.white,
      tertiary: AppColors.amber,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: -0.5,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.mist,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.mist),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.mistDim),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        fontSize: 20,
      ),
      iconTheme: const IconThemeData(color: AppColors.cyan),
    ),
    cardTheme: CardThemeData(
      color: AppColors.navySurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.cyan, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.navyLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.mistDim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.navyLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navyLight,
      indicatorColor: AppColors.cyan.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.cyan);
        }
        return const IconThemeData(color: AppColors.mistDim);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelSmall?.copyWith(color: AppColors.cyan);
        }
        return textTheme.labelSmall?.copyWith(color: AppColors.mistDim);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navySurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.mist),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.navyLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
