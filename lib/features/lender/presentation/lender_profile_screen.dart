import 'dart:ui';
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
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.08),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          // Main Content
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colLenders)
                .doc(lenderId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: AppColors.emerald));
              }
              if (!snap.data!.exists) {
                return Center(
                    child: Text('Lender not found', style: AppTextStyles.h3));
              }
              final lender = LenderModel.fromMap(
                  snap.data!.data() as Map<String, dynamic>, snap.data!.id);
              return _LenderProfileBody(
                  lender: lender, ref: ref, context: context);
            },
          ),
        ],
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
          expandedHeight: 200,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: AppIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
                bgColor: Colors.black26),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.transparent,
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    SizedBox(height: 30),
                    // Glass Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: Offset(0, 8))
                          ]),
                      child: Center(
                          child: Text(
                        lender.businessName.isNotEmpty
                            ? lender.businessName[0].toUpperCase()
                            : 'L',
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white),
                      )),
                    ).animate().scale(
                        delay: 100.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack),
                    SizedBox(height: 12),
                    Text(lender.businessName, style: AppTextStyles.h2)
                        .animate()
                        .fadeIn(delay: 200.ms),
                    SizedBox(height: 2),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_on_rounded,
                          color: AppColors.textMuted, size: 14),
                      SizedBox(width: 4),
                      Text(lender.city,
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      if (lender.isVerified) VerifiedBadge(small: true),
                    ]).animate().fadeIn(delay: 300.ms),
                  ])),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2x2 Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  padding: EdgeInsets.zero,
                  children: [
                    _GlassStatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Capital',
                        value: AppFormatters.formatINRCompact(
                            lender.availableCapital),
                        color: AppColors.gold),
                    _GlassStatCard(
                        icon: Icons.percent_rounded,
                        label: 'Interest',
                        value: '${lender.interestRatePerMonth}%/mo',
                        color: AppColors.emerald),
                    _GlassStatCard(
                        icon: Icons.handshake_rounded,
                        label: 'Deals',
                        value: '${lender.completedDeals}',
                        color: AppColors.info),
                    _GlassStatCard(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: lender.rating.toStringAsFixed(1),
                        color: AppColors.warning),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, duration: 400.ms),

                SizedBox(height: 24),

                // Loan Range inside Glass Container
                Text('Loan Details', style: AppTextStyles.h3)
                    .animate()
                    .fadeIn(delay: 150.ms),
                SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.glassBg,
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ]),
                  child: Column(
                    children: [
                      _GlassDetailRow(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Min Loan',
                          value: AppFormatters.formatINR(lender.minLoanAmount)),
                      Divider(
                          color: AppColors.border.withValues(alpha: 0.5),
                          height: 16),
                      _GlassDetailRow(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Max Loan',
                          value: AppFormatters.formatINR(lender.maxLoanAmount)),
                      Divider(
                          color: AppColors.border.withValues(alpha: 0.5),
                          height: 16),
                      _GlassDetailRow(
                          icon: Icons.calendar_month_rounded,
                          label: 'Max Tenure',
                          value: AppFormatters.formatTenure(
                              lender.maxTenureMonths)),
                      Divider(
                          color: AppColors.border.withValues(alpha: 0.5),
                          height: 16),
                      _GlassDetailRow(
                          icon: Icons.pie_chart_rounded,
                          label: 'LTV Ratio',
                          value: AppFormatters.formatLTV(lender.ltvRatio)),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                SizedBox(height: 24),

                // Collateral
                Text('Accepted Collateral', style: AppTextStyles.h3)
                    .animate()
                    .fadeIn(delay: 250.ms),
                SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: lender.acceptedCollateral
                      .map((c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.info.withValues(alpha: 0.3)),
                            ),
                            child: Text(c,
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                ).animate().fadeIn(delay: 300.ms),

                SizedBox(height: 24),

                if (lender.description?.isNotEmpty == true) ...[
                  Text('About', style: AppTextStyles.h3),
                  SizedBox(height: 8),
                  Text(lender.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary, height: 1.5)),
                  SizedBox(height: 24),
                ],

                // Reviews
                _ReviewsSection(lenderId: lender.id),

                SizedBox(height: 16), // Reduced spacing

                // Modern Floating Action Dock
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.glassBg,
                                blurRadius: 20,
                                offset: Offset(0, 10))
                          ]),
                      child: Row(
                        children: [
                          // Unlock Contact
                          Expanded(
                            flex: 4,
                            child: InkWell(
                              onTap: () =>
                                  context.push('/unlock-contact/${lender.id}'),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                height: 56,
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.lock_outline_rounded,
                                          color: AppColors.textPrimary,
                                          size: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Unlock Contact',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                          Text(
                                              '₹${AppConstants.contactUnlockBasic}',
                                              style: AppTextStyles.h3.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Send Request
                          Expanded(
                            flex: 5,
                            child: InkWell(
                              onTap: () {
                                final currentUser =
                                    ref.read(currentUserProvider).valueOrNull;
                                if (currentUser?.isVerified != true) {
                                  _showVerificationDialog(context);
                                } else {
                                  context.push('/match?lenderId=${lender.id}');
                                }
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                    color: AppColors.emerald,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppColors.emerald
                                              .withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: Offset(0, 5))
                                    ]),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Send Request',
                                        style: AppTextStyles.h3.copyWith(
                                            color: Colors.white, fontSize: 14)),
                                    SizedBox(width: 6),
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                SizedBox(height: 32), // Reduced bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Verification Required', style: AppTextStyles.h3),
        content: Text(
            'You must complete KYC verification before sending a loan request.',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Cancel', style: AppTextStyles.bodyMedium)),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              context.push('/kyc');
            },
            child: Text('Verify Now',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.emerald, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _GlassStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: AppColors.glassBg, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              SizedBox(width: 8),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          Spacer(),
          Text(value, style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

class _GlassDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _GlassDetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        SizedBox(width: 12),
        Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        Spacer(),
        Text(value, style: AppTextStyles.h3),
      ],
    );
  }
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
            SizedBox(height: 16),
            ...snap.data!.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.glassBg,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.gold.withValues(alpha: 0.1),
                          child: Text(
                            (data['reviewerName'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(data['reviewerName'] ?? '',
                            style: AppTextStyles.labelLarge),
                        Spacer(),
                        StarRating(
                            rating: (data['rating'] ?? 0).toDouble(),
                            compact: true),
                      ]),
                      SizedBox(height: 12),
                      Text(data['comment'] ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary, height: 1.4)),
                    ]),
              );
            }),
          ],
        );
      },
    );
  }
}
