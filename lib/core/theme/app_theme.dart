import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.light(
          primary: AppColors.gold,
          secondary: AppColors.emerald,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),

        // AppBar — transparent/bg color
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle:
              AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
          actionsIconTheme:
              IconThemeData(color: AppColors.textPrimary, size: 24),
        ),

        // Bottom Navigation — white with Indigo selected
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              AppTextStyles.labelSmall.copyWith(color: AppColors.gold),
          unselectedLabelStyle: AppTextStyles.labelSmall,
        ),

        // Navigation Bar (M3)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.gold.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
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

        // Cards — white, highly rounded, no border
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),

        // Inputs — Pill shaped, white fill
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: AppColors.border, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: AppColors.border, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: AppColors.emerald, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
          labelStyle: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textSecondary),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withOpacity(0.8)),
          errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          prefixIconColor: AppColors.textSecondary.withOpacity(0.8),
          suffixIconColor: AppColors.textSecondary.withOpacity(0.8),
        ),

        // Elevated Button — Pill shaped
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            textStyle: AppTextStyles.button,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),

        // Outlined Button — Pill shaped
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: BorderSide(color: AppColors.border, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            textStyle: AppTextStyles.button,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),

        // Text Button
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            textStyle: AppTextStyles.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),

        // Chip — Pill shaped
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceAlt,
          selectedColor: AppColors.gold.withOpacity(0.12),
          side: BorderSide.none,
          labelStyle: AppTextStyles.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),

        // Divider
        dividerTheme: DividerThemeData(
          color: AppColors.border,
          space: 1,
          thickness: 1,
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle:
              AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),

        // Dialog
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: AppTextStyles.h3,
          contentTextStyle: AppTextStyles.bodyMedium,
          elevation: 0,
        ),

        // Bottom Sheet
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBackgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        // Tab Bar
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.gold, width: 2.5),
          ),
        ),

        // FAB
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.gold
                  : AppColors.textMuted),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.gold.withOpacity(0.3)
                  : AppColors.border),
        ),

        // Progress Indicator
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColors.gold,
          linearTrackColor: AppColors.border,
        ),

        // Text theme
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          displaySmall: AppTextStyles.displaySmall,
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          headlineSmall: AppTextStyles.h3,
          titleLarge: AppTextStyles.h3,
          titleMedium: AppTextStyles.h4,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),
      );

  // Dark theme — pure black, no blue tint
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF52C41A),
          secondary: Color(0xFF52C41A),
          surface: Color(0xFF0D0D0D),
          error: Color(0xFFFF4D4F),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFFFFFFF),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0D0D0D),
          selectedItemColor: Color(0xFF52C41A),
          unselectedItemColor: Color(0xFF666666),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D0D0D),
          indicatorColor: const Color(0xFF52C41A).withOpacity(0.15),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141414),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF222222),
          space: 1,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0D0D0D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0D0D0D),
          modalBackgroundColor: Color(0xFF0D0D0D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          displaySmall: AppTextStyles.displaySmall,
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          headlineSmall: AppTextStyles.h3,
          titleLarge: AppTextStyles.h3,
          titleMedium: AppTextStyles.h4,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),
      );
}
