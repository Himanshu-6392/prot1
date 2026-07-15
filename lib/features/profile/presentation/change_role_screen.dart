import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';

class ChangeRoleScreen extends ConsumerStatefulWidget {
  const ChangeRoleScreen({super.key});

  @override
  ConsumerState<ChangeRoleScreen> createState() => _ChangeRoleScreenState();
}

class _ChangeRoleScreenState extends ConsumerState<ChangeRoleScreen> {
  UserRole? selectedRole;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    selectedRole = user?.role ?? UserRole.borrower;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Change Role', style: AppTextStyles.h3),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Your Path',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 50.ms).slideY(begin: -0.1),
            const SizedBox(height: 8),
            Text(
              'You can be a borrower, a lender, or both.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),
            _RoleOptionCard(
              title: 'Borrower',
              description: 'I want to request loans.',
              icon: Icons.handshake_rounded,
              color: AppColors.gold,
              isSelected: selectedRole == UserRole.borrower,
              onTap: () => setState(() => selectedRole = UserRole.borrower),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            const SizedBox(height: 16),
            _RoleOptionCard(
              title: 'Lender',
              description: 'I want to fund loans and earn interest.',
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.emerald,
              isSelected: selectedRole == UserRole.lender,
              onTap: () => setState(() => selectedRole = UserRole.lender),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
            const SizedBox(height: 16),
            _RoleOptionCard(
              title: 'Both',
              description: 'I want to do both.',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.info,
              isSelected: selectedRole == UserRole.both,
              onTap: () => setState(() => selectedRole = UserRole.both),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
            const Spacer(),
            GestureDetector(
              onTap: isSaving
                  ? null
                  : () async {
                      if (selectedRole == null) return;
                      setState(() => isSaving = true);

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          'role': selectedRole!.name,
                        }).catchError(
                                (e) => print('Background sync error: $e'));
                      }

                      if (context.mounted) {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Role changed successfully! 🎉'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                alignment: Alignment.center,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Save Preferences',
                        style: AppTextStyles.h4.copyWith(color: Colors.white)),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 28)
                  .animate()
                  .scale(duration: 300.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}
