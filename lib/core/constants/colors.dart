import 'package:flutter/material.dart';

/// Centralized repository of colors across YOLO Business Mobile.
/// Follows DRY and Clean Architecture principles.
abstract final class AppColors {
  // Brand
  static const Color brandBlue = Color(0xFF034BFF);
  static const Color primary = brandBlue;

  // Base
  static const Color ink = Color(0xFF121317);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color muted = Color(0xFF73757B);
  static const Color darkMuted = Color(0xFFA0A3AA);

  // Light Palette
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF6F6F6);
  static const Color lightSurfaceHighest = Color(0xFFEFEFEF);
  static const Color lightBorder = Color(0xFFEDEDED);
  static const Color lightTextPrimary = ink;
  static const Color lightTextSecondary = muted;

  // Dark Palette
  static const Color darkBackground = Color(0xFF121317);
  static const Color darkSurface = Color(0xFF1C1E24);
  static const Color darkSurfaceHighest = Color(0xFF262932);
  static const Color darkBorder = Color(0xFF323642);
  static const Color darkTextPrimary = Color(0xFFF6F6F6);
  static const Color darkTextSecondary = darkMuted;

  // Feedback & Semantic
  static const Color error = Color(0xFFB3261E);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFF9AB00);
}
