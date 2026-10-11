import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/lender_bookmark_button.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/saved_lenders_provider.dart';

class SavedLendersScreen extends ConsumerWidget {
  const SavedLendersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedListAsync = ref.watch(savedLendersListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned(
            top: -100,
            right: -60,
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
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom App Bar Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => context.pop(),
                        bgColor: AppColors.surface,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved Lenders',
                              style: AppTextStyles.h2.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bookmarked lender profiles & loan offers',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      savedListAsync.maybeWhen(
                        data: (items) => items.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.emerald.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${items.length} Saved',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.5),
                ),

                // Content
                Expanded(
                  child: savedListAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      itemCount: 4,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: RequestCardShimmer(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error loading saved lenders: $err'),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald
                                          .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.emerald
                                          .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.bookmark_outline_rounded,
                                        size: 38,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                  ).animate().scale(
                                        duration: 400.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No saved lenders yet',
                                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Save lenders you're interested in to find their profiles and loan offers quickly.",
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  AppButton(
                                    label: 'Explore Lenders',
                                    icon: const Icon(Icons.explore_rounded,
                                        size: 18),
                                    width: 200,
                                    color: AppColors.emerald,
                                    onPressed: () => context.push('/search'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final lenderId = (item['lenderId'] ?? '').toString();

                          return _SavedLenderItemCard(
                            lenderId: lenderId,
                            savedData: item,
                          )
                              .animate()
                              .fadeIn(
                                  delay: (index * 60).ms, duration: 350.ms)
                              .slideY(begin: 0.06, curve: Curves.easeOut);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLenderItemCard extends ConsumerWidget {
  final String lenderId;
  final Map<String, dynamic> savedData;

  const _SavedLenderItemCard({
    required this.lenderId,
    required this.savedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessName = (savedData['businessName'] ?? 'Lender').toString();
    final city = (savedData['city'] ?? 'India').toString();
    final isVerified = savedData['isVerified'] == true;
    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'L';

    // Stream live lender doc to keep numbers current if updated
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLenders)
          .doc(lenderId)
          .snapshots(),
      builder: (context, snap) {
        Map<String, dynamic> data = savedData;
        if (snap.hasData && snap.data!.exists) {
          data = Map<String, dynamic>.from(snap.data!.data() as Map<String, dynamic>);
        }

        final double maxLoan = (data['maxLoanAmount'] ?? savedData['maxLoanAmount'] ?? 0).toDouble();
        final double rate = (data['interestRatePerMonth'] ?? savedData['interestRatePerMonth'] ?? 0).toDouble();
        final int tenure = (data['maxTenureMonths'] ?? savedData['maxTenureMonths'] ?? 0).toInt();
        final collaterals = (data['acceptedCollateral'] is List)
            ? (data['acceptedCollateral'] as List).map((e) => e.toString()).toList()
            : <String>[];
        final String collateralStr = collaterals.isNotEmpty ? collaterals.join(', ') : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                context.push('/lender-profile/$lenderId');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar, Name & Location, Bookmark Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.emeraldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      businessName,
                                      style: AppTextStyles.h3.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.verified_rounded,
                                        color: AppColors.emerald, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      color: AppColors.textMuted, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    city,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Active Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'Active Lender',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Bookmark Save/Unsave Button
                        LenderBookmarkButton(
                          lenderId: lenderId,
                          businessName: businessName,
                          city: city,
                          isVerified: isVerified,
                          size: 22,
                          padding: const EdgeInsets.all(6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Compact Loan Details Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Max Loan',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                maxLoan > 0
                                    ? AppFormatters.formatINR(maxLoan)
                                    : '₹5,00,000',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Rate',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                rate > 0 ? '$rate%/mo' : '1.5%/mo',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Tenure',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                tenure > 0
                                    ? AppFormatters.formatTenure(tenure)
                                    : 'Flexible',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom Row: Collateral Badge & Chevron to Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (collateralStr.isNotEmpty)
                          TagChip(
                            label: 'Accepts: $collateralStr',
                            color: AppColors.info,
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            Text(
                              'View Lender Profile',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.emerald,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
