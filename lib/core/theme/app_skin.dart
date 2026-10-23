import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A color skin. Light and dark mode stay a separate setting.
enum AppSkin {
  clear(
    label: 'Clear',
    lightPrimary: AppColors.teal,
    darkPrimary: AppColors.tealGlow,
    lightBackground: AppColors.lightBackground,
    lightOnSurface: AppColors.lightOnSurface,
    lightOutline: Color(0xFFC5D4CE),
    lightOutlineVariant: Color(0xFFDCE7E2),
    darkBackground: AppColors.darkBackground,
    darkSurface: AppColors.darkSurface,
    darkOnSurface: AppColors.darkOnSurface,
    darkOnPrimary: Color(0xFF06201C),
    darkOutline: Color(0xFF4A635C),
    darkOutlineVariant: Color(0xFF2C3F38),
  ),
  ocean(
    label: 'Ocean',
    lightPrimary: Color(0xFF1A6A9A),
    darkPrimary: Color(0xFF7EC8E8),
    lightBackground: Color(0xFFF2F6F9),
    lightOnSurface: Color(0xFF12202A),
    lightOutline: Color(0xFFC3D2DE),
    lightOutlineVariant: Color(0xFFD9E5EE),
    darkBackground: Color(0xFF0B1218),
    darkSurface: Color(0xFF15202A),
    darkOnSurface: Color(0xFFE3EEF5),
    darkOnPrimary: Color(0xFF04202C),
    darkOutline: Color(0xFF3E5668),
    darkOutlineVariant: Color(0xFF243644),
  ),
  dusk(
    label: 'Dusk',
    lightPrimary: Color(0xFF5C4D8A),
    darkPrimary: Color(0xFFC4B4E8),
    lightBackground: Color(0xFFF5F3F8),
    lightOnSurface: Color(0xFF1A1624),
    lightOutline: Color(0xFFD0C8DC),
    lightOutlineVariant: Color(0xFFE4DEEC),
    darkBackground: Color(0xFF100E16),
    darkSurface: Color(0xFF1C1826),
    darkOnSurface: Color(0xFFECE8F4),
    darkOnPrimary: Color(0xFF1A1028),
    darkOutline: Color(0xFF544A68),
    darkOutlineVariant: Color(0xFF322C40),
  ),
  ember(
    label: 'Ember',
    lightPrimary: Color(0xFF9C4E28),
    darkPrimary: Color(0xFFF0A56A),
    lightBackground: Color(0xFFF8F4F0),
    lightOnSurface: Color(0xFF241812),
    lightOutline: Color(0xFFE0D0C4),
    lightOutlineVariant: Color(0xFFEDE2D8),
    darkBackground: Color(0xFF16110E),
    darkSurface: Color(0xFF241C18),
    darkOnSurface: Color(0xFFF4EBE4),
    darkOnPrimary: Color(0xFF2A1408),
    darkOutline: Color(0xFF6A5244),
    darkOutlineVariant: Color(0xFF3A2C24),
  ),
  blossom(
    label: 'Blossom',
    lightPrimary: Color(0xFF8E3F58),
    darkPrimary: Color(0xFFF0A0B4),
    lightBackground: Color(0xFFF8F3F5),
    lightOnSurface: Color(0xFF241418),
    lightOutline: Color(0xFFE0CCD4),
    lightOutlineVariant: Color(0xFFEEDDE4),
    darkBackground: Color(0xFF160E12),
    darkSurface: Color(0xFF24181C),
    darkOnSurface: Color(0xFFF6E8EC),
    darkOnPrimary: Color(0xFF2A1018),
    darkOutline: Color(0xFF684854),
    darkOutlineVariant: Color(0xFF3A2830),
  ),
  stone(
    label: 'Stone',
    lightPrimary: Color(0xFF3E4A45),
    darkPrimary: Color(0xFFC5D0CB),
    lightBackground: Color(0xFFF4F5F4),
    lightOnSurface: Color(0xFF1A1E1C),
    lightOutline: Color(0xFFD0D4D2),
    lightOutlineVariant: Color(0xFFE2E6E4),
    darkBackground: Color(0xFF101211),
    darkSurface: Color(0xFF1A1E1C),
    darkOnSurface: Color(0xFFE6EAE8),
    darkOnPrimary: Color(0xFF1A221F),
    darkOutline: Color(0xFF4E5854),
    darkOutlineVariant: Color(0xFF2A312E),
  );

  const AppSkin({
    required this.label,
    required this.lightPrimary,
    required this.darkPrimary,
    required this.lightBackground,
    required this.lightOnSurface,
    required this.lightOutline,
    required this.lightOutlineVariant,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkOnSurface,
    required this.darkOnPrimary,
    required this.darkOutline,
    required this.darkOutlineVariant,
  });

  final String label;
  final Color lightPrimary;
  final Color darkPrimary;
  final Color lightBackground;
  final Color lightOnSurface;
  final Color lightOutline;
  final Color lightOutlineVariant;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkOnSurface;
  final Color darkOnPrimary;
  final Color darkOutline;
  final Color darkOutlineVariant;

  /// Accent shown on the settings swatch for the current brightness.
  Color previewColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : lightPrimary;
  }

  /// Icon color that stays readable on [previewColor].
  Color previewOnColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkOnPrimary : Colors.white;
  }

  /// Loads a saved skin. Missing or unknown ids stay on Clear.
  static AppSkin fromName(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return AppSkin.clear;
    }
    for (final skin in AppSkin.values) {
      if (skin.name == raw) {
        return skin;
      }
    }
    return AppSkin.clear;
  }
}
