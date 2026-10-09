import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// PeerLend Brand Palette — Light-First Design
// Inspired by reference: Indigo + Emerald + Slate
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Background layers
  static Color bg = const Color(0xFFF6F7FB); // Very light grayish blue
  static Color surface = const Color(0xFFFFFFFF); // Pure white
  static Color surfaceAlt = const Color(0xFFF3F4F6); // Gray 100
  static Color surfaceHigh = const Color(0xFFE5E7EB); // Gray 200

  // Brand — Dark Primary, Vibrant Green Secondary
  static Color gold = const Color(0xFF18181B); // Black/Dark Gray
  static Color goldLight = const Color(0xFF3F3F46); // Lighter Gray
  static Color emerald = const Color(0xFF52C41A); // Vibrant Green
  static Color emeraldDark = const Color(0xFF389E0D); // Darker Green

  // Semantic
  static Color success = const Color(0xFF52C41A);
  static Color warning = const Color(0xFFFAAD14);
  static Color error = const Color(0xFFFF4D4F);
  static Color info = const Color(0xFF1890FF);

  // Text
  static Color textPrimary = const Color(0xFF111827); // Very dark slate
  static Color textSecondary = const Color(0xFF6B7280); // Gray 500
  static Color textMuted = const Color(0xFF9CA3AF); // Gray 400
  static Color textInverse = const Color(0xFFFFFFFF); // White

  // Borders
  static Color border = const Color(0xFFE5E7EB); // Gray 200
  static Color borderGlow = const Color(0x1A000000); // Soft black shadow

  // Glass
  static Color glassBg = const Color(0x0A000000);
  static Color glassBorder = const Color(0x1A000000);

  // Gradients
  static LinearGradient goldGradient = const LinearGradient(
    colors: [Color(0xFF27272A), Color(0xFF18181B)], // Dark gray to black
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static LinearGradient emeraldGradient = const LinearGradient(
    colors: [
      Color(0xFF7AE582),
      Color(0xFF52C41A)
    ], // Light green to vibrant green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient bgGradient = const LinearGradient(
    colors: [Color(0xFFF6F7FB), Color(0xFFF3F4F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGradient = const LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static RadialGradient goldGlow = const RadialGradient(
    colors: [Color(0x1A000000), Color(0x00000000)],
    radius: 0.8,
  );

  // ─── Theme Switcher Methods ────────────────

  static void setLight() {
    isDarkMode = false;
    bg = const Color(0xFFF6F7FB);
    surface = const Color(0xFFFFFFFF);
    surfaceAlt = const Color(0xFFF3F4F6);
    surfaceHigh = const Color(0xFFE5E7EB);
    gold = const Color(0xFF18181B);
    goldLight = const Color(0xFF3F3F46);
    emerald = const Color(0xFF52C41A);
    emeraldDark = const Color(0xFF389E0D);
    textPrimary = const Color(0xFF111827);
    textSecondary = const Color(0xFF6B7280);
    textMuted = const Color(0xFF9CA3AF);
    textInverse = const Color(0xFFFFFFFF);
    border = const Color(0xFFE5E7EB);
    borderGlow = const Color(0x1A000000);
    glassBg = const Color(0x0A000000);
    glassBorder = const Color(0x1A000000);
    goldGradient = const LinearGradient(
        colors: [Color(0xFF27272A), Color(0xFF18181B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(
        colors: [Color(0xFF7AE582), Color(0xFF52C41A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    bgGradient = const LinearGradient(
        colors: [Color(0xFFF6F7FB), Color(0xFFF3F4F6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
    cardGradient = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
  }

  static void setDark() {
    isDarkMode = true;
    bg = const Color(0xFF000000);           // Pure black background
    surface = const Color(0xFF0D0D0D);      // Near-black surface
    surfaceAlt = const Color(0xFF141414);   // Slightly lighter surface
    surfaceHigh = const Color(0xFF1A1A1A);  // Card surface
    gold = const Color(0xFF52C41A);         // Keep green as primary accent
    goldLight = const Color(0xFF7AE582);    // Lighter green
    emerald = const Color(0xFF52C41A);
    emeraldDark = const Color(0xFF389E0D);
    textPrimary = const Color(0xFFFFFFFF);  // Pure white text
    textSecondary = const Color(0xFFB0B0B0); // Mid-gray
    textMuted = const Color(0xFF666666);    // Dark gray
    textInverse = const Color(0xFF000000);
    border = const Color(0xFF222222);       // Subtle dark border
    borderGlow = const Color(0x3352C41A);   // Green glow
    glassBg = const Color(0x1AFFFFFF);
    glassBorder = const Color(0x1AFFFFFF);
    goldGradient = const LinearGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    emeraldGradient = const LinearGradient(
        colors: [Color(0xFF7AE582), Color(0xFF52C41A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    bgGradient = const LinearGradient(
        colors: [Color(0xFF000000), Color(0xFF0A0A0A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);
    cardGradient = const LinearGradient(
        colors: [Color(0xFF141414), Color(0xFF0D0D0D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight);
    goldGlow = const RadialGradient(
      colors: [Color(0x1A52C41A), Color(0x0052C41A)],
      radius: 0.8,
    );
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
