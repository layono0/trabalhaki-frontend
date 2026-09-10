import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palette defined in projeto-react-css.md
  static const Color primary = Color(0xFF393BE7);
  static const Color secondary = Color(0xFF86E5A1);
  static const Color accent = Color(0xFF280F9F);
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);

  // Aux / Neutral colors
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color border = Color(0xFFE2E8F0);
  static const Color redPass = Color(0xFFF87171); // red-400
  static const Color starYellow = Color(0xFFEAB308); // yellow-500

  // Tag background & text colors
  static const Color greenTagBg = Color(0xFFF0FDF4); // green-50
  static const Color greenTagText = Color(0xFF15803D); // green-700
  static const Color blueTagBg = Color(0xFFEFF6FF); // blue-50
  static const Color blueTagText = Color(0xFF1D4ED8); // blue-700
  static const Color purpleTagBg = Color(0xFFFAF5FF); // purple-50
  static const Color purpleTagText = Color(0xFF7E22CE); // purple-700
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
