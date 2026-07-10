import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null || user.role != UserRole.admin) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.admin_panel_settings_rounded,
              color: AppColors.error, size: 64),
          SizedBox(height: 16),
          Text('Access Denied', style: AppTextStyles.h2),
          Text('Admin access required',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Admin Panel'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: AppColors.error, size: 14),
              SizedBox(width: 4),
              Text('Admin',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.error)),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _AdminStat(
                  label: 'Total Users',
                  value: '—',
                  icon: Icons.people_rounded,
                  color: AppColors.gold),
              _AdminStat(
                  label: 'Active Lenders',
                  value: '—',
                  icon: Icons.savings_rounded,
                  color: AppColors.emerald),
              _AdminStat(
                  label: 'Open Requests',
                  value: '—',
                  icon: Icons.description_rounded,
                  color: AppColors.info),
              _AdminStat(
                  label: 'KYC Pending',
                  value: '—',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning),
            ],
          ).animate().fadeIn(),

          SizedBox(height: 24),
          Text('Quick Actions', style: AppTextStyles.h3)
              .animate()
              .fadeIn(delay: 100.ms),
          SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: [
              _AdminAction(
                  icon: Icons.verified_user_rounded,
                  label: 'Verify KYC',
                  color: AppColors.emerald,
                  onTap: () {}),
              _AdminAction(
                  icon: Icons.block_rounded,
                  label: 'Block User',
                  color: AppColors.error,
                  onTap: () {}),
              _AdminAction(
                  icon: Icons.card_membership_rounded,
                  label: 'Subscriptions',
                  color: AppColors.gold,
                  onTap: () {}),
              _AdminAction(
                  icon: Icons.flag_rounded,
                  label: 'Reports',
                  color: AppColors.warning,
                  onTap: () {}),
              _AdminAction(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  color: AppColors.info,
                  onTap: () {}),
              _AdminAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  color: AppColors.textSecondary,
                  onTap: () {}),
            ],
          ).animate().fadeIn(delay: 150.ms),

          SizedBox(height: 24),
          Text('KYC Verification Queue', style: AppTextStyles.h3)
              .animate()
              .fadeIn(delay: 200.ms),
          SizedBox(height: 12),

          // KYC Queue
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colUsers)
                .where('kycStatus', isEqualTo: KycStatus.submitted.name)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return Center(
                    child: CircularProgressIndicator(color: AppColors.gold));
              final docs = snap.data!.docs;
              if (docs.isEmpty)
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald, size: 20),
                    SizedBox(width: 10),
                    Text('All KYC submissions verified!',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.emerald)),
                  ]),
                );

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return _KycQueueItem(uid: d.id, data: data);
                }).toList(),
              );
            },
          ).animate().fadeIn(delay: 250.ms),

          SizedBox(height: 24),
          Text('Recent Reports', style: AppTextStyles.h3)
              .animate()
              .fadeIn(delay: 300.ms),
          SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Center(
                child: Text('No reports filed',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted))),
          ).animate().fadeIn(delay: 350.ms),

          SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AdminStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18)),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: AppTextStyles.h2.copyWith(color: color)),
                Text(label,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ]),
      );
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22)),
            SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2),
          ]),
        ),
      );
}

class _KycQueueItem extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  const _KycQueueItem({required this.uid, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text((data['name'] ?? 'U')[0].toUpperCase(),
                    style: AppTextStyles.labelLarge))),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['name'] ?? 'Unknown', style: AppTextStyles.labelLarge),
          Text(data['email'] ?? '', style: AppTextStyles.caption),
        ])),
        Row(children: [
          GestureDetector(
            onTap: () =>
                FirebaseFirestore.instance.collection('users').doc(uid).update({
              'kycStatus': KycStatus.verified.name,
              'isVerified': true,
            }),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Approve',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.emerald))),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                FirebaseFirestore.instance.collection('users').doc(uid).update({
              'kycStatus': KycStatus.rejected.name,
            }),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Reject',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.error))),
          ),
        ]),
      ]),
    );
  }
}
