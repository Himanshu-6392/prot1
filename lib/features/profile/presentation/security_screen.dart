import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/pin_entry_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);
    final isPinSet = securityState.isPinSet;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Security & Privacy', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 36),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: 32),

          Text('App Lock', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.pin_rounded,
            title: isPinSet ? 'Change App PIN' : 'Set App PIN',
            subtitle: 'Secure your app and sensitive data',
            color: AppColors.info,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // TODO: Navigation to set/change PIN
            },
          ),

          const SizedBox(height: 32),
          Text('Data Privacy', style: AppTextStyles.h4),
          const SizedBox(height: 16),

          _buildOptionTile(
            icon: Icons.pin_rounded,
            title: isPinSet ? 'Change 4-Digit PIN' : 'Set 4-Digit PIN',
            subtitle: 'Used to reveal sensitive financial data',
            color: AppColors.emerald,
            onTap: () {
              showPinDialog(context, ref, forceSetup: true);
            },
            trailing: Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
