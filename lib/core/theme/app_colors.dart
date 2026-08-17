import 'package:flutter/material.dart';

/// Spendly brand color palette with Light and Dark tokens.
///
/// Deep teal conveys trust and professionalism; amber provides warmth
/// and draws attention to key actions and amounts.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF149D9B);
  static const Color primaryDark = Color(0xFF07484B);

  static const Color secondary = Color(0xFFF2A922);
  static const Color secondaryLight = Color(0xFFF5C566);
  static const Color secondaryDark = Color(0xFFC98A0E);

  // ── Light Theme Tokens ─────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textHint = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE9ECEF);
  static const Color shadow = Color(0x1A000000);

  // ── Dark Theme Tokens ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121418);
  static const Color darkSurface = Color(0xFF1E2228);
  static const Color darkSurfaceVariant = Color(0xFF282E37);
  static const Color darkTextPrimary = Color(0xFFEAEAEA);
  static const Color darkTextSecondary = Color(0xFFA0A6B1);
  static const Color darkTextHint = Color(0xFF6C757D);
  static const Color darkDivider = Color(0xFF2F3642);

  // ── Semantic ───────────────────────────────────────────────────────
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  static const Color shimmer = Color(0xFFE0E0E0);

  // ── Chart palette ──────────────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF0D7377),
    Color(0xFFF2A922),
    Color(0xFF6C5CE7),
    Color(0xFFE17055),
    Color(0xFF00B894),
    Color(0xFFFD79A8),
    Color(0xFF636E72),
    Color(0xFF0984E3),
    Color(0xFFD63031),
    Color(0xFF00CEC9),
    Color(0xFFA29BFE),
  ];
}
