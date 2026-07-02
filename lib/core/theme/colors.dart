import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// PeerLend Brand Palette (Dynamic Theme Engine)
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Background layers
  static Color bg          = const Color(0xFFF8FAFC);
  static Color surface     = const Color(0xFFFFFFFF);
  static Color surfaceAlt  = const Color(0xFFF1F5F9);
  static Color surfaceHigh = const Color(0xFFE2E8F0);

  // Brand
  static Color gold        = const Color(0xFF6366F1); // Indigo
  static Color goldLight   = const Color(0xFF8B5CF6); // Violet
  static Color emerald     = const Color(0xFF00C78B);
  static Color emeraldDark = const Color(0xFF00A070);

  // Semantic
  static Color success     = const Color(0xFF16A34A);
  static Color warning     = const Color(0xFFF5A623);
  static Color error       = const Color(0xFFDC2626);
  static Color info        = const Color(0xFF2563EB);

  // Text
  static Color textPrimary   = const Color(0xFF0F172A);
  static Color textSecondary = const Color(0xFF475569);
  static Color textMuted     = const Color(0xFF94A3B8);
  static Color textInverse   = const Color(0xFFFFFFFF);

  // Borders
  static Color border        = const Color(0xFFE2E8F0);
  static Color borderGlow    = const Color(0x33F5A623);

  // Glass
  static Color glassBg       = const Color(0x0A000000);
  static Color glassBorder   = const Color(0x1A000000);

  // Gradients
  static LinearGradient goldGradient = const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient emeraldGradient = const LinearGradient(
    colors: [Color(0xFF00C78B), Color(0xFF00A070)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient bgGradient = const LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );

  static LinearGradient cardGradient = const LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static RadialGradient goldGlow = const RadialGradient(
    colors: [Color(0x306366F1), Color(0x006366F1)],
    radius: 0.8,
  );

  // ─── Theme Switcher Methods ────────────────

  static void setLight() {
    isDarkMode    = false;
    bg            = const Color(0xFFF8FAFC); // Very clean Slate 50
    surface       = const Color(0xFFFFFFFF); // Pure white cards
    surfaceAlt    = const Color(0xFFF1F5F9); // Slightly darker for inner elements
    surfaceHigh   = const Color(0xFFE2E8F0);
    gold          = const Color(0xFF3B82F6); // Professional Electric Blue accent
    goldLight     = const Color(0xFF60A5FA); 
    emerald       = const Color(0xFF10B981); 
    emeraldDark   = const Color(0xFF059669);
    textPrimary   = const Color(0xFF0F172A); // Deep Slate
    textSecondary = const Color(0xFF64748B); // Slate Gray
    textMuted     = const Color(0xFF94A3B8);
    textInverse   = const Color(0xFFFFFFFF);
    border        = const Color(0xFFE2E8F0); 
    glassBg       = const Color(0x00000000); 
    glassBorder   = const Color(0x00000000);
    goldGradient  = const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    bgGradient    = const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight); 
    cardGradient  = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  static void setDark() {
    isDarkMode    = true;
    bg            = const Color(0xFF0A0E1A);
    surface       = const Color(0xFF111827);
    surfaceAlt    = const Color(0xFF1A2235);
    surfaceHigh   = const Color(0xFF1E2D45);
    gold          = const Color(0xFF6366F1); // Indigo
    goldLight     = const Color(0xFF8B5CF6); // Violet
    emerald       = const Color(0xFF00E5A0);
    emeraldDark   = const Color(0xFF00B57D);
    textPrimary   = const Color(0xFFF1F5F9);
    textSecondary = const Color(0xFF94A3B8);
    textMuted     = const Color(0xFF4B5563);
    textInverse   = const Color(0xFF0A0E1A);
    border        = const Color(0xFF1E293B);
    glassBg       = const Color(0x1AFFFFFF);
    glassBorder   = const Color(0x26FFFFFF);
    goldGradient  = const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B57D)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    bgGradient    = const LinearGradient(colors: [Color(0xFF0A0E1A), Color(0xFF0D1628)], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    cardGradient  = const LinearGradient(colors: [Color(0xFF1A2235), Color(0xFF111827)], begin: Alignment.topLeft, end: Alignment.bottomRight);
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
