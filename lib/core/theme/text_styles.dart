import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(color: AppColors.textPrimary);

  // Display
  static TextStyle get displayLarge  => _base.copyWith(fontSize: 48, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1.5);
  static TextStyle get displayMedium => _base.copyWith(fontSize: 38, fontWeight: FontWeight.w700, height: 1.15, letterSpacing: -1.0);
  static TextStyle get displaySmall  => _base.copyWith(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5);

  // Headings
  static TextStyle get h1 => _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25);
  static TextStyle get h2 => _base.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static TextStyle get h3 => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35);
  static TextStyle get h4 => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4);

  // Body
  static TextStyle get bodyLarge  => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.55);
  static TextStyle get bodySmall  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);

  // Labels
  static TextStyle get labelLarge  => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5);
  static TextStyle get labelMedium => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4);
  static TextStyle get labelSmall  => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3, color: AppColors.textSecondary);

  // Captions & Tags
  static TextStyle get caption    => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
  static TextStyle get tag        => _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8);

  // Amount / Currency
  static TextStyle get amountLarge  => _base.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.gold, height: 1.1);
  static TextStyle get amountMedium => _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold, height: 1.1);
  static TextStyle get amountSmall  => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gold);

  // Button
  static TextStyle get button => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3);
}
