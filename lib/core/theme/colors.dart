import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// PeerLend Brand Palette — Light-First Design
// Inspired by reference: Indigo + Emerald + Slate
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Background layers
  static Color bg = const Color(0xFFF8FAFC); // Slate 50
  static Color surface = const Color(0xFFFFFFFF); // Pure white
  static Color surfaceAlt = const Color(0xFFF1F5F9); // Slate 100
  static Color surfaceHigh = const Color(0xFFE2E8F0); // Slate 200

  // Brand — Indigo Primary, Emerald Secondary
  static Color gold = const Color(0xFF4F46E5); // Indigo 600
  static Color goldLight = const Color(0xFF818CF8); // Indigo 400
  static Color emerald = const Color(0xFF059669); // Emerald 600
  static Color emeraldDark = const Color(0xFF047857); // Emerald 700

  // Semantic
  static Color success = const Color(0xFF059669);
  static Color warning = const Color(0xFFF59E0B);
  static Color error = const Color(0xFFDC2626);
  static Color info = const Color(0xFF3B82F6);

  // Text
  static Color textPrimary = const Color(0xFF0F172A); // Slate 900
  static Color textSecondary = const Color(0xFF475569); // Slate 600
  static Color textMuted = const Color(0xFF94A3B8); // Slate 400
  static Color textInverse = const Color(0xFFFFFFFF);

  // Borders
  static Color border = const Color(0xFFE2E8F0); // Slate 200
  static Color borderGlow = const Color(0x334F46E5);

  // Glass
  static Color glassBg = const Color(0x0A000000);
  static Color glassBorder = const Color(0x1A000000);

  // Gradients
  static LinearGradient goldGradient = const LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)], // Deep Indigo → Indigo
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient emeraldGradient = const LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient bgGradient = const LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGradient = const LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static RadialGradient goldGlow = const RadialGradient(
    colors: [Color(0x304F46E5), Color(0x004F46E5)],
    radius: 0.8,
  );

  // ─── Theme Switcher Methods ────────────────

  static void setLight() {
    isDarkMode = false;
    bg = const Color(0xFFF8FAFC);
    surface = const Color(0xFFFFFFFF);
    surfaceAlt = const Color(0xFFF1F5F9);
    surfaceHigh = const Color(0xFFE2E8F0);
    gold = const Color(0xFF4F46E5); // Indigo
    goldLight = const Color(0xFF818CF8); // Indigo light
    emerald = const Color(0xFF059669);
    emeraldDark = const Color(0xFF047857);
    textPrimary = const Color(0xFF0F172A);
    textSecondary = const Color(0xFF475569);
    textMuted = const Color(0xFF94A3B8);
    textInverse = const Color(0xFFFFFFFF);
    border = const Color(0xFFE2E8F0);
    borderGlow = const Color(0x334F46E5);
    glassBg = const Color(0x0A000000);
    glassBorder = const Color(0x1A000000);
    goldGradient = const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(
        colors: [Color(0xFF047857), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    bgGradient = const LinearGradient(
        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
    cardGradient = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
  }

  static void setDark() {
    isDarkMode = true;
    bg = const Color(0xFF0A0E1A);
    surface = const Color(0xFF111827);
    surfaceAlt = const Color(0xFF1A2235);
    surfaceHigh = const Color(0xFF1E2D45);
    gold = const Color(0xFF818CF8); // Indigo light for dark mode
    goldLight = const Color(0xFFA5B4FC);
    emerald = const Color(0xFF34D399);
    emeraldDark = const Color(0xFF10B981);
    textPrimary = const Color(0xFFF1F5F9);
    textSecondary = const Color(0xFF94A3B8);
    textMuted = const Color(0xFF4B5563);
    textInverse = const Color(0xFF0A0E1A);
    border = const Color(0xFF1E293B);
    borderGlow = const Color(0x33818CF8);
    glassBg = const Color(0x1AFFFFFF);
    glassBorder = const Color(0x26FFFFFF);
    goldGradient = const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF818CF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    bgGradient = const LinearGradient(
        colors: [Color(0xFF0A0E1A), Color(0xFF0D1628)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
    cardGradient = const LinearGradient(
        colors: [Color(0xFF1A2235), Color(0xFF111827)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
  }

  static void toggleTheme(BuildContext context) {
    if (isDarkMode) {
      setLight();
    } else {
      setDark();
    }

    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement != null) {
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }

      rootElement.visitChildren(rebuild);
    }
  }
}
