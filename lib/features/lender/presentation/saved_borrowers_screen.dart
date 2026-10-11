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
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/saved_borrowers_provider.dart';

class SavedBorrowersScreen extends ConsumerWidget {
  const SavedBorrowersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedListAsync = ref.watch(savedBorrowersListProvider);

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
                              'Saved Borrowers',
                              style: AppTextStyles.h2.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bookmarked borrower profiles & requests',
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
                      child: Text('Error loading saved borrowers: $err'),
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
                                    'No saved borrowers yet',
                                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Save borrowers you're interested in to find their profiles and loan requests quickly.",
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  AppButton(
                                    label: 'Explore Borrowers',
                                    icon: const Icon(Icons.explore_rounded,
                                        size: 18),
                                    width: 200,
                                    color: AppColors.emerald,
                                    onPressed: () =>
                                        context.push('/borrower-search'),
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
                          final bId = (item['borrowerId'] ?? '').toString();

                          return _SavedBorrowerItemCard(
                            borrowerId: bId,
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

class _SavedBorrowerItemCard extends ConsumerWidget {
  final String borrowerId;
  final Map<String, dynamic> savedData;

  const _SavedBorrowerItemCard({
    required this.borrowerId,
    required this.savedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrowerName = (savedData['borrowerName'] ?? 'Borrower').toString();
    final city = (savedData['borrowerCity'] ?? 'India').toString();
    final isVerified = savedData['isVerified'] == true;
    final initial = borrowerName.isNotEmpty ? borrowerName[0].toUpperCase() : 'B';

    // Stream live request status for this borrower to keep it current
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colRequests)
          .where('borrowerId', isEqualTo: borrowerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, reqSnap) {
        final docs = reqSnap.data?.docs ?? [];
        final openDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['status'] ?? 'open') == 'open';
        }).toList();

        final hasOpenRequests = openDocs.isNotEmpty;
        final latestReqData = hasOpenRequests
            ? openDocs.first.data() as Map<String, dynamic>
            : (docs.isNotEmpty ? docs.first.data() as Map<String, dynamic> : savedData);

        final double loanAmount =
            (latestReqData['loanAmount'] ?? savedData['loanAmount'] ?? 0).toDouble();
        final tenure = latestReqData['tenureMonths'] ?? savedData['tenureMonths'] ?? 0;
        final maxRate =
            latestReqData['maxInterestRatePerMonth'] ?? savedData['maxInterestRatePerMonth'] ?? '-';
        final collateralType = (latestReqData['collateralType'] ??
                savedData['collateralType'] ??
                '')
            .toString();

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
                context.push('/borrower-profile/$borrowerId');
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
                                      borrowerName,
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

                        // Active Requests Count Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasOpenRequests
                                ? AppColors.emerald.withValues(alpha: 0.1)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasOpenRequests
                                  ? AppColors.emerald.withValues(alpha: 0.25)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            hasOpenRequests
                                ? '${openDocs.length} Open Req'
                                : 'No Open Req',
                            style: AppTextStyles.caption.copyWith(
                              color: hasOpenRequests
                                  ? AppColors.emerald
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Bookmark Save/Unsave Button
                        BookmarkButton(
                          borrowerId: borrowerId,
                          borrowerName: borrowerName,
                          borrowerCity: city,
                          isVerified: isVerified,
                          size: 22,
                          padding: const EdgeInsets.all(6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Compact Request Summary or Inactive Status
                    if (loanAmount > 0)
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
                                Text('Requested Loan',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.formatINR(loanAmount),
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
                                Text('Max Rate',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '$maxRate%/mo',
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
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Profile saved • No active loan requests at the moment',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Bottom Row: Collateral Badge & Chevron to Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (collateralType.isNotEmpty)
                          TagChip(
                            label: 'Collateral: $collateralType',
                            color: AppColors.info,
                          )
                        else
                          const SizedBox(),
                        Row(
                          children: [
                            Text(
                              'View Profile',
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
