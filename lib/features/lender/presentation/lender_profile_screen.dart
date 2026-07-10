import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lender_model.dart';
import '../../../core/providers/firebase_providers.dart';

class LenderProfileScreen extends ConsumerWidget {
  final String lenderId;
  const LenderProfileScreen({super.key, required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colLenders)
            .doc(lenderId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (!snap.data!.exists) {
            return Center(
                child: Text('Lender not found', style: AppTextStyles.h3));
          }
          final lender = LenderModel.fromMap(
              snap.data!.data() as Map<String, dynamic>, snap.data!.id);
          return _LenderProfileBody(lender: lender, ref: ref, context: context);
        },
      ),
    );
  }
}

class _LenderProfileBody extends StatelessWidget {
  final LenderModel lender;
  final WidgetRef ref;
  final BuildContext context;

  const _LenderProfileBody(
      {required this.lender, required this.ref, required this.context});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: AppIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
              bgColor: Colors.black26),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surfaceHigh, AppColors.bg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    SizedBox(height: 60),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withOpacity(0.4),
                                blurRadius: 24)
                          ]),
                      child: Center(
                          child: Text(
                        lender.businessName.isNotEmpty
                            ? lender.businessName[0].toUpperCase()
                            : 'L',
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white),
                      )),
                    ),
                    SizedBox(height: 10),
                    Text(lender.businessName, style: AppTextStyles.h2),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.textMuted, size: 14),
                      Text(lender.city, style: AppTextStyles.caption),
                      SizedBox(width: 12),
                      if (lender.isVerified) VerifiedBadge(small: true),
                    ]),
                  ])),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileStat(
                          label: 'Capital',
                          value: AppFormatters.formatINRCompact(
                              lender.availableCapital),
                          color: AppColors.gold),
                      _ProfileStat(
                          label: 'Interest',
                          value: '${lender.interestRatePerMonth}%/mo',
                          color: AppColors.warning),
                      _ProfileStat(
                          label: 'Deals',
                          value: '${lender.completedDeals}',
                          color: AppColors.emerald),
                      _ProfileStat(
                          label: 'Rating',
                          value: lender.rating.toStringAsFixed(1),
                          color: AppColors.gold),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                SizedBox(height: 20),

                // Loan Range
                Text('Loan Details', style: AppTextStyles.h3)
                    .animate()
                    .fadeIn(delay: 150.ms),
                SizedBox(height: 12),
                _DetailRow(
                    'Min Loan', AppFormatters.formatINR(lender.minLoanAmount)),
                _DetailRow(
                    'Max Loan', AppFormatters.formatINR(lender.maxLoanAmount)),
                _DetailRow('Max Tenure',
                    AppFormatters.formatTenure(lender.maxTenureMonths)),
                _DetailRow(
                    'LTV Ratio', AppFormatters.formatLTV(lender.ltvRatio)),

                SizedBox(height: 20),

                // Collateral
                Text('Accepted Collateral', style: AppTextStyles.h3)
                    .animate()
                    .fadeIn(delay: 200.ms),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lender.acceptedCollateral
                      .map((c) => TagChip(label: c, color: AppColors.info))
                      .toList(),
                ).animate().fadeIn(delay: 220.ms),

                SizedBox(height: 20),

                if (lender.description?.isNotEmpty == true) ...[
                  Text('About', style: AppTextStyles.h3),
                  SizedBox(height: 8),
                  Text(lender.description!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 20),
                ],

                // Reviews
                _ReviewsSection(lenderId: lender.id),

                SizedBox(height: 24),

                // CTA
                AppButton(
                  label: 'Send Loan Request',
                  onPressed: () {
                    final currentUser =
                        ref.read(currentUserProvider).valueOrNull;
                    if (currentUser?.isVerified != true) {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppColors.surfaceAlt,
                          title: Text('Verification Required',
                              style: AppTextStyles.h3),
                          content: Text(
                              'You must complete KYC verification before sending a loan request.',
                              style: AppTextStyles.bodyMedium),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: Text('Cancel',
                                    style: AppTextStyles.bodyMedium)),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(c);
                                context.push('/profile/kyc');
                              },
                              child: Text('Verify Now',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      context.push('/match?lenderId=${lender.id}');
                    }
                  },
                  icon: Icon(Icons.send_rounded, size: 18),
                ).animate().fadeIn(delay: 300.ms),

                SizedBox(height: 12),

                AppButton(
                  label: 'Unlock Contact (₹${AppConstants.contactUnlockBasic})',
                  isOutlined: true,
                  onPressed: () => context.push('/unlock-contact/${lender.id}'),
                  icon: Icon(Icons.lock_open_rounded, size: 18),
                ).animate().fadeIn(delay: 350.ms),

                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ProfileStat(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ]);
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Spacer(),
          Text(value, style: AppTextStyles.labelMedium),
        ]),
      );
}

class _ReviewsSection extends ConsumerWidget {
  final String lenderId;
  const _ReviewsSection({required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colReviews)
          .where('targetId', isEqualTo: lenderId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reviews', style: AppTextStyles.h3).animate().fadeIn(),
            SizedBox(height: 12),
            ...snap.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(data['reviewerName'] ?? '',
                            style: AppTextStyles.labelLarge),
                        Spacer(),
                        StarRating(
                            rating: (data['rating'] ?? 0).toDouble(),
                            compact: true),
                      ]),
                      SizedBox(height: 4),
                      Text(data['comment'] ?? '',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ]),
              );
            }),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
