import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _RoleCard({
    required this.icon, required this.title, required this.description,
    required this.isSelected, required this.onTap, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve:    Curves.easeInOut,
        padding:  const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:        isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
            color:  isSelected ? color : AppColors.border,
            width:  isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, spreadRadius: 1),
          ] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60, height: 60,
              decoration: BoxDecoration(
                color:        isSelected ? color.withOpacity(0.15) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3.copyWith(
                    color: isSelected ? color : AppColors.textPrimary,
                  )),
                  SizedBox(height: 4),
                  Text(description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 24)
                  : Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionState();
}

class _RoleSelectionState extends ConsumerState<RoleSelectionScreen> {
  final _roles = <UserRole>{};
  bool _loading = false;

  Future<void> _save() async {
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one role')),
      );
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    final role = _roles.contains(UserRole.lender) && _roles.contains(UserRole.borrower)
        ? UserRole.both
        : _roles.first;

    await ref.read(firestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .update({'role': role.name, 'updatedAt': FieldValue.serverTimestamp()});

    if (mounted) {
      if (_roles.contains(UserRole.lender)) {
        context.go('/auth/kyc-lender');
      } else {
        context.go('/auth/kyc-borrower');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Your Role', style: AppTextStyles.displaySmall)
                    .animate().fadeIn(duration: 400.ms),
                SizedBox(height: 8),
                Text('You can switch between roles any time from settings.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))
                    .animate().fadeIn(delay: 100.ms),

                SizedBox(height: 40),

                _RoleCard(
                  icon:        Icons.account_balance_wallet_rounded,
                  title:       'Borrower',
                  description: 'Post loan requests and connect with verified lenders.',
                  isSelected:  _roles.contains(UserRole.borrower),
                  color:       AppColors.gold,
                  onTap: () {
                    setState(() {
                      if (_roles.contains(UserRole.borrower)) {
                        _roles.remove(UserRole.borrower);
                      } else {
                        _roles.add(UserRole.borrower);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                SizedBox(height: 16),

                _RoleCard(
                  icon:        Icons.savings_rounded,
                  title:       'Lender',
                  description: 'List your available capital and earn interest on secured loans.',
                  isSelected:  _roles.contains(UserRole.lender),
                  color:       AppColors.emerald,
                  onTap: () {
                    setState(() {
                      if (_roles.contains(UserRole.lender)) {
                        _roles.remove(UserRole.lender);
                      } else {
                        _roles.add(UserRole.lender);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),

                SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        AppColors.gold.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: AppColors.gold.withOpacity(0.15)),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_rounded, color: AppColors.gold, size: 16),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'You can select both roles and switch between dashboards anytime.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    )),
                  ]),
                ).animate().fadeIn(delay: 400.ms),

                Spacer(),

                AppButton(
                  label:     'Continue',
                  onPressed: _save,
                  isLoading: _loading,
                  icon:      Icon(Icons.arrow_forward_rounded, size: 18),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
