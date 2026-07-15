import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _loading = false;

  Future<void> _updateSubscription(bool makePremium) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'isPremium': makePremium,
        'subscriptionPlan': makePremium ? 'premium' : 'basic',
        if (makePremium)
          'subscriptionExpiry':
              DateTime.now().add(const Duration(days: 30)).toIso8601String()
        else
          'subscriptionExpiry': FieldValue.delete(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                makePremium ? 'Upgraded to Premium' : 'Downgraded to Basic')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateKycStatus(KycStatus status) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'kycStatus': status.name,
        'isVerified': status == KycStatus.verified,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('KYC updated to ${status.name}')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock(bool block) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'isBlocked': block,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(block ? 'User Blocked' : 'User Unblocked')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all users and find this one. (For a real app, a userStreamProvider by ID is better, but we already have allUsersProvider)
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('User Details')),
      body: usersAsync.when(
        data: (users) {
          final user = users.firstWhere((u) => u.uid == widget.userId,
              orElse: () => throw Exception('User not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.gold,
                        child: Text(user.name[0].toUpperCase(),
                            style:
                                AppTextStyles.h1.copyWith(color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 12),
                      Text(user.name, style: AppTextStyles.h2),
                      Text(user.email,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted)),
                      if (user.isBlocked)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('BLOCKED',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Subscription Section
                Text('Subscription', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Plan:',
                              style: AppTextStyles.bodyMedium),
                          Text(user.isPremium ? 'PREMIUM' : 'BASIC',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: user.isPremium
                                      ? AppColors.gold
                                      : AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (user.isPremium)
                        AppButton(
                            label: 'Revoke Premium',
                            onPressed: _loading
                                ? null
                                : () => _updateSubscription(false),
                            isOutlined: true)
                      else
                        AppButton(
                            label: 'Grant Premium',
                            onPressed: _loading
                                ? null
                                : () => _updateSubscription(true)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // KYC Section
                Text('KYC Verification', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status:', style: AppTextStyles.bodyMedium),
                          Text(user.kycStatus.name.toUpperCase(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: user.kycStatus == KycStatus.verified
                                      ? AppColors.emerald
                                      : AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: AppButton(
                            label: 'Approve',
                            onPressed: (_loading ||
                                    user.kycStatus == KycStatus.verified)
                                ? null
                                : () => _updateKycStatus(KycStatus.verified),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: AppButton(
                            label: 'Reject',
                            isOutlined: true,
                            onPressed: (_loading ||
                                    user.kycStatus == KycStatus.rejected)
                                ? null
                                : () => _updateKycStatus(KycStatus.rejected),
                          )),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Danger Zone
                Text('Danger Zone',
                    style: AppTextStyles.h3.copyWith(color: AppColors.error)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3))),
                  child: Column(
                    children: [
                      if (user.isBlocked)
                        AppButton(
                            label: 'Unblock User',
                            onPressed:
                                _loading ? null : () => _toggleBlock(false))
                      else
                        AppButton(
                            label: 'Block User',
                            onPressed:
                                _loading ? null : () => _toggleBlock(true),
                            isOutlined: true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
