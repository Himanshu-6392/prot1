import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Base fonts
  static TextStyle get _jakarta =>
      GoogleFonts.plusJakartaSans(color: AppColors.textPrimary);
  static TextStyle get _inter =>
      GoogleFonts.inter(color: AppColors.textPrimary);

  // Display (Jakarta — bold headings)
  static TextStyle get displayLarge => _jakarta.copyWith(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -1.5);
  static TextStyle get displayMedium => _jakarta.copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -1.0);
  static TextStyle get displaySmall => _jakarta.copyWith(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5);

  // Headings (Jakarta)
  static TextStyle get h1 => _jakarta.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.25,
      letterSpacing: -0.5);
  static TextStyle get h2 => _jakarta.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.3,
      letterSpacing: -0.5);
  static TextStyle get h3 => _jakarta.copyWith(
      fontSize: 18, fontWeight: FontWeight.w700, height: 1.35);
  static TextStyle get h4 =>
      _jakarta.copyWith(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4);

  // Body (Inter)
  static TextStyle get bodyLarge =>
      _inter.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);
  static TextStyle get bodyMedium =>
      _inter.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55);
  static TextStyle get bodySmall => _inter.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.5);

  // Labels (Jakarta semi-bold)
  static TextStyle get labelLarge => _jakarta.copyWith(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelMedium => _jakarta.copyWith(
      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static TextStyle get labelSmall => _jakarta.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: AppColors.textSecondary);

  // Captions & Tags (Inter)
  static TextStyle get caption => _inter.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
      height: 1.4);
  static TextStyle get tag => _jakarta.copyWith(
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0);

  // Amount / Currency (Jakarta bold)
  static TextStyle get amountLarge => _jakarta.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -1.0);
  static TextStyle get amountMedium => _jakarta.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.25,
      letterSpacing: -0.5);
  static TextStyle get amountSmall => _jakarta.copyWith(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // Button (Jakarta bold)
  static TextStyle get button => _jakarta.copyWith(
      fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2);
}
