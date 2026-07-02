import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.dark(
      primary:          AppColors.gold,
      secondary:        AppColors.emerald,
      surface:          AppColors.surface,
      error:            AppColors.error,
      onPrimary:        AppColors.textInverse,
      onSecondary:      AppColors.textInverse,
      onSurface:        AppColors.textPrimary,
      onError:          Colors.white,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor:   AppColors.bg,
      elevation:         0,
      scrolledUnderElevation: 0,
      centerTitle:       false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle:    AppTextStyles.h2,
      iconTheme:         IconThemeData(color: AppColors.textPrimary, size: 24),
    ),

    // Bottom Nav
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:          AppColors.surface,
      selectedItemColor:        AppColors.gold,
      unselectedItemColor:      AppColors.textMuted,
      type:                     BottomNavigationBarType.fixed,
      elevation:                0,
    ),

    // Navigation Bar (M3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:           AppColors.surface,
      indicatorColor:            AppColors.gold.withOpacity(0.18),
      labelTextStyle:            WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(color: AppColors.gold);
        }
        return AppTextStyles.labelSmall;
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: AppColors.gold, size: 22);
        }
        return IconThemeData(color: AppColors.textMuted, size: 22);
      }),
      elevation: 0,
    ),

    // Cards
    cardTheme: CardThemeData(
      color:        AppColors.surface,
      elevation:    0,
      shape:        RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      margin:       const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        AppColors.surfaceAlt,
      contentPadding:   const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(12),
        borderSide:     BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(12),
        borderSide:     BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(12),
        borderSide:     BorderSide(color: AppColors.gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(12),
        borderSide:     BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius:   BorderRadius.circular(12),
        borderSide:     BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle:    AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
      hintStyle:     AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
      errorStyle:    AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.gold,
        foregroundColor:  AppColors.textInverse,
        elevation:        0,
        shadowColor:      AppColors.gold.withOpacity(0.4),
        padding:          const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        textStyle:        AppTextStyles.button,
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize:      const Size(double.infinity, 52),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:  AppColors.gold,
        side:             BorderSide(color: AppColors.gold, width: 1.5),
        padding:          const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        textStyle:        AppTextStyles.button,
        shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize:      const Size(double.infinity, 52),
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        textStyle:       AppTextStyles.labelLarge,
        padding:         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor:    AppColors.surfaceAlt,
      selectedColor:      AppColors.gold.withOpacity(0.18),
      side:               BorderSide(color: AppColors.border),
      labelStyle:         AppTextStyles.labelSmall,
      padding:            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape:              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color:   AppColors.border,
      space:   1,
      thickness: 1,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor:    AppColors.surfaceHigh,
      contentTextStyle:   AppTextStyles.bodyMedium,
      shape:              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior:           SnackBarBehavior.floating,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle:  AppTextStyles.h3,
      contentTextStyle: AppTextStyles.bodyMedium,
    ),

    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor:     AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor:         AppColors.gold,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle:         AppTextStyles.labelLarge,
      unselectedLabelStyle: AppTextStyles.labelLarge,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.gold, width: 2.5),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.textInverse,
      elevation:       8,
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.gold : AppColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.gold.withOpacity(0.3) : AppColors.border),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor:   AppColors.gold,
      inactiveTrackColor: AppColors.border,
      thumbColor:         AppColors.gold,
      overlayColor:       AppColors.borderGlow,
    ),

    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color:            AppColors.gold,
      linearTrackColor: AppColors.border,
    ),

    // Text
    textTheme: TextTheme(
      displayLarge:  AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall:  AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleLarge:    AppTextStyles.h3,
      titleMedium:   AppTextStyles.h4,
      bodyLarge:     AppTextStyles.bodyLarge,
      bodyMedium:    AppTextStyles.bodyMedium,
      bodySmall:     AppTextStyles.bodySmall,
      labelLarge:    AppTextStyles.labelLarge,
      labelMedium:   AppTextStyles.labelMedium,
      labelSmall:    AppTextStyles.labelSmall,
    ),
  );
}
