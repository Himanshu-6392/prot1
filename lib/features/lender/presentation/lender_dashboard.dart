import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/user_model.dart';

class LenderDashboard extends ConsumerWidget {
  const LenderDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _LenderHeader(user: user)),
            SliverToBoxAdapter(child: _LenderStatsRow(userId: user?.uid ?? '')),
            SliverToBoxAdapter(child: _ManageSection(userId: user?.uid ?? '')),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Incoming Requests',
                onSeeAll: () => context.push('/borrower-search'),
              ),
            ),
            _IncomingRequestsSliver(lenderId: user?.uid ?? ''),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-offer'),
        icon:      Icon(Icons.edit_rounded),
        label:     Text('Manage Offer'),
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.textInverse,
      ),
    );
  }
}

class _LenderHeader extends StatelessWidget {
  final UserModel? user;
  const _LenderHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lender Dashboard', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text(user?.name ?? 'Lender', style: AppTextStyles.h1),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient:     AppColors.emeraldGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.savings_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text('Lender', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
          ]),
        ),
      ]),
    );
  }
}

class _LenderStatsRow extends ConsumerWidget {
  final String userId;
  const _LenderStatsRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _StatCard2(label: 'Available Capital', value: '₹5L', icon: Icons.account_balance_wallet_rounded, color: AppColors.gold),
          _StatCard2(label: 'Active Offers', value: '2', icon: Icons.receipt_long_rounded, color: AppColors.emerald),
          _StatCard2(label: 'Requests Received', value: '8', icon: Icons.inbox_rounded, color: AppColors.info),
          _StatCard2(label: 'Accepted Deals', value: '6', icon: Icons.handshake_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard2({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTextStyles.amountSmall.copyWith(color: color, fontSize: 22, height: 1)),
            Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

class _ManageSection extends ConsumerWidget {
  final String userId;
  const _ManageSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: _ActionTile(
          icon: Icons.person_search_rounded, label: 'Browse Borrowers', color: AppColors.gold,
          onTap: () => context.push('/borrower-search'),
        )),
        SizedBox(width: 12),
        Expanded(child: _ActionTile(
          icon: Icons.edit_note_rounded, label: 'Edit Offer', color: AppColors.emerald,
          onTap: () => context.push('/create-offer'),
        )),
        SizedBox(width: 12),
        Expanded(child: _ActionTile(
          icon: Icons.workspace_premium_rounded, label: 'Go Premium', color: AppColors.info,
          onTap: () => context.push('/plans'),
        )),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center, maxLines: 2),
        ]),
      ),
    );
  }
}

class _IncomingRequestsSliver extends ConsumerWidget {
  final String lenderId;
  const _IncomingRequestsSliver({required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colRequests)
            .where('status', isEqualTo: 'open')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(children: [RequestCardShimmer(), RequestCardShimmer()]);
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No open requests',
              subtitle: 'New borrower requests will appear here.',
            );
          }
          return Column(
            children: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _IncomingCard(data: data, id: d.id);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const _IncomingCard({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/request/$id'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(
              AppFormatters.formatINR((data['loanAmount'] ?? 0).toDouble()),
              style: AppTextStyles.amountMedium,
            )),
            TagChip(label: data['collateralType'] ?? '', color: AppColors.info),
          ]),
          SizedBox(height: 8),
          Text(data['description'] ?? '', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 10),
          Row(children: [
            Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 13),
            SizedBox(width: 4),
            Text(data['borrowerCity'] ?? '', style: AppTextStyles.caption),
            SizedBox(width: 12),
            Icon(Icons.percent_rounded, color: AppColors.textMuted, size: 13),
            SizedBox(width: 4),
            Text('Max ${data['maxInterestRatePerMonth'] ?? '-'}%/mo', style: AppTextStyles.caption),
            Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Respond', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
            ),
          ]),
        ]),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }
}
