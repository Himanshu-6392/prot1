import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/platform_settings_provider.dart';

// ─────────────────────────────────────────────────────────────
// Maintenance Screen
// Shown to all non-admin users when maintenanceMode is ON.
// Listens to maintenanceModeProvider in real-time — the moment
// admin turns maintenance OFF, all users are automatically
// redirected back to the app via the router guard.
// ─────────────────────────────────────────────────────────────
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch live — when admin turns maintenance OFF this widget
    // disappears automatically because the router redirects.
    ref.watch(maintenanceModeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated Icon ──────────────────────────
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.15),
                          const Color(0xFF8B5CF6).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      size: 52,
                      color: Color(0xFF6366F1),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.06, 1.06),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 40),

                  // ── Title ─────────────────────────────────
                  Text(
                    'Under Maintenance',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // ── Subtitle ──────────────────────────────
                  Text(
                    'PeerLend is currently undergoing scheduled maintenance to improve your experience.\n\nWe\'ll be back shortly!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 48),

                  // ── Animated Dots ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(
                            onPlay: (c) => c.repeat(),
                            delay: Duration(milliseconds: i * 200),
                          )
                          .scaleXY(
                            begin: 0.5,
                            end: 1.2,
                            duration: 600.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scaleXY(begin: 1.2, end: 0.5, duration: 600.ms);
                    }),
                  ),

                  const SizedBox(height: 56),

                  // ── Info pill ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'You will be redirected automatically\nwhen maintenance ends.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
