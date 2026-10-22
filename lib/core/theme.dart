import 'package:flutter/material.dart';
import 'constants/colors.dart';

abstract final class YoloTheme {
  static const ink = AppColors.ink;
  static const muted = AppColors.muted;
  static const surface = AppColors.lightSurface;
  static const border = AppColors.lightBorder;
  static const brandBlue = AppColors.brandBlue;

  static Color mutedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkMuted
          : AppColors.muted;

  static ThemeData get light {
    final text = ThemeData.light().textTheme.apply(
      fontFamily: 'Barlow Semi Condensed',
    );
    final scheme = const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerHighest: AppColors.lightSurface,
      outline: AppColors.lightBorder,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      textTheme: text.copyWith(
        headlineLarge: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.05,
          color: AppColors.ink,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Barlow Semi Condensed',
          fontSize: 17,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Barlow Semi Condensed',
          fontSize: 15,
          color: AppColors.ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(
            fontFamily: 'Barlow Semi Condensed',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.ink),
        ),
        hintStyle: const TextStyle(color: AppColors.muted),
        helperStyle: const TextStyle(color: AppColors.muted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        space: 32,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.ink,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get dark {
    final text = ThemeData.dark().textTheme.apply(
      fontFamily: 'Barlow Semi Condensed',
    );
    final scheme = const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: AppColors.ink,
      secondary: Colors.white,
      onSecondary: AppColors.ink,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkMuted,
      surfaceContainerHighest: AppColors.darkSurfaceHighest,
      outline: AppColors.darkBorder,
      error: AppColors.darkError,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      textTheme: text.copyWith(
        headlineLarge: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 38,
          fontWeight: FontWeight.w700,
          height: 1.05,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Barlow Condensed',
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Barlow Semi Condensed',
          fontSize: 17,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Barlow Semi Condensed',
          fontSize: 15,
          color: AppColors.darkTextPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          minimumSize: const Size(double.infinity, 54),
          textStyle: const TextStyle(
            fontFamily: 'Barlow Semi Condensed',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceHighest,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
        hintStyle: const TextStyle(color: AppColors.darkMuted),
        helperStyle: const TextStyle(color: AppColors.darkMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        space: 32,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceHighest,
        selectedColor: Colors.white,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceHighest,
        contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
      ),
    );
  }
}
