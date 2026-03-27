import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF914700);
  static const Color onPrimary = Color(0xFFFFF0E8);
  static const Color primaryContainer = Color(0xFFFD8100);
  static const Color onPrimaryContainer = Color(0xFF3F1B00);
  
  // Secondary
  static const Color secondary = Color(0xFF005F99);
  static const Color onSecondary = Color(0xFFECF3FF);
  static const Color secondaryContainer = Color(0xFFB0D5FF);
  static const Color onSecondaryContainer = Color(0xFF004A79);

  // Tertiary
  static const Color tertiary = Color(0xFFBA0013);
  static const Color onTertiary = Color(0xFFFFEFED);
  static const Color tertiaryContainer = Color(0xFFFF9288);
  static const Color onTertiaryContainer = Color(0xFF690006);

  // Error
  static const Color error = Color(0xFFB02500);
  static const Color onError = Color(0xFFFFEFEC);
  static const Color errorContainer = Color(0xFFF95630);
  static const Color onErrorContainer = Color(0xFF520C00);

  // Surface
  static const Color surface = Color(0xFFF4F7F8);
  static const Color onSurface = Color(0xFF2B2F30);
  static const Color surfaceVariant = Color(0xFFD8DEDF);
  static const Color onSurfaceVariant = Color(0xFF585C5D);
  static const Color background = Color(0xFFF4F7F8);
  static const Color onBackground = Color(0xFF2B2F30);

  // Surface Containers (New Material 3)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF1F2);
  static const Color surfaceContainer = Color(0xFFE5E9EA);
  static const Color surfaceContainerHigh = Color(0xFFDEE3E5);
  static const Color surfaceContainerHighest = Color(0xFFD8DEDF);

  // Outline
  static const Color outline = Color(0xFF747778);
  static const Color outlineVariant = Color(0xFFAAAEAF);

  // Specific Orange branding helper
  static const Color orange600 = Color(0xFFEA580C); // From Tailwind
  static const Color orange500 = Color(0xFFF97316); // From Tailwind
  static const Color orange100 = Color(0xFFFFEDD5); // From Tailwind
  static const Color orange50 = Color(0xFFFFF7ED);  // From Tailwind
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
    );

    // Using Plus Jakarta Sans for Display/Headlines and Work Sans for Body/Labels
    final displayFont = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final bodyFont = GoogleFonts.workSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: displayFont.copyWith(
        displayLarge: displayFont.displayLarge,
        displayMedium: displayFont.displayMedium,
        displaySmall: displayFont.displaySmall,
        headlineLarge: displayFont.headlineLarge,
        headlineMedium: displayFont.headlineMedium,
        headlineSmall: displayFont.headlineSmall,
        
        bodyLarge: bodyFont.bodyLarge,
        bodyMedium: bodyFont.bodyMedium,
        bodySmall: bodyFont.bodySmall,
        labelLarge: bodyFont.labelLarge,
        labelMedium: bodyFont.labelMedium,
        labelSmall: bodyFont.labelSmall,
        titleLarge: displayFont.titleLarge,
        titleMedium: bodyFont.titleMedium,
        titleSmall: bodyFont.titleSmall,
      ),
    );
  }
}
