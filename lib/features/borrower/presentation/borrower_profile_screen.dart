import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/user_model.dart';
import '../../../models/loan_request_model.dart';
import '../../../models/match_model.dart';
import '../../../core/providers/firebase_providers.dart';

class BorrowerProfileScreen extends ConsumerWidget {
  final String borrowerId;
  const BorrowerProfileScreen({super.key, required this.borrowerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
        ref.watch(currentUserProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.07),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // Main Streams
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(borrowerId)
                .snapshots(),
            builder: (context, userSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colRequests)
                    .where('borrowerId', isEqualTo: borrowerId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, reqSnap) {
                  // If both streams are waiting for initial load
                  if (userSnap.connectionState == ConnectionState.waiting &&
                      !userSnap.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.emerald),
                    );
                  }

                  // Resolve user data with fallback to request data if user doc is missing
                  UserModel? user;
                  if (userSnap.hasData && userSnap.data!.exists) {
                    user = UserModel.fromMap(
                      userSnap.data!.data() as Map<String, dynamic>,
                      userSnap.data!.id,
                    );
                  }

                  // Parse requests
                  final List<LoanRequestModel> requests = [];
                  if (reqSnap.hasData) {
                    for (final doc in reqSnap.data!.docs) {
                      try {
                        requests.add(LoanRequestModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ));
                      } catch (_) {}
                    }
                  }

                  // Fallback user if users collection doc doesn't exist
                  if (user == null) {
                    final fallbackName = requests.isNotEmpty
                        ? requests.first.borrowerName
                        : 'Borrower';
                    final fallbackCity = requests.isNotEmpty
                        ? requests.first.borrowerCity
                        : 'India';
                    final fallbackVerified = requests.isNotEmpty
                        ? requests.first.isVerified
                        : false;

                    user = UserModel(
                      uid: borrowerId,
                      name: fallbackName,
                      email: '',
                      phone: '',
                      role: UserRole.borrower,
                      city: fallbackCity,
                      isVerified: fallbackVerified,
                      kycStatus: fallbackVerified
                          ? KycStatus.verified
                          : KycStatus.pending,
                      createdAt: requests.isNotEmpty
                          ? requests.first.createdAt
                          : DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                  }

                  return _BorrowerProfileBody(
                    user: user,
                    requests: requests,
                    currentUserId: currentUserId,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BorrowerProfileBody extends StatelessWidget {
  final UserModel user;
  final List<LoanRequestModel> requests;
  final String? currentUserId;

  const _BorrowerProfileBody({
    required this.user,
    required this.requests,
    this.currentUserId,
  });

  Future<void> _startOrOpenChat(BuildContext context) async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat with this borrower')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
      );

      final matchesQuery = await FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .where('borrowerId', isEqualTo: user.uid)
          .where('lenderId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (matchesQuery.docs.isNotEmpty) {
        if (context.mounted) {
          Navigator.pop(context); // close loader
          final existing = matchesQuery.docs.first;
          final roomId = existing.data()['chatRoomId'] ?? '${existing.id}_chat';
          context.push('/chat/$roomId', extra: user);
        }
        return;
      }

      // Create new match & room
      final matchRef =
          FirebaseFirestore.instance.collection(AppConstants.colMatches).doc();
      final roomId = '${matchRef.id}_chat';
      final match = MatchModel(
        id: matchRef.id,
        borrowerId: user.uid,
        lenderId: currentUserId!,
        requestId: requests.isNotEmpty ? requests.first.id : '',
        chatRoomId: roomId,
        status: MatchStatus.accepted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await matchRef.set(match.toMap());

      if (context.mounted) {
        Navigator.pop(context); // close loader
        context.push('/chat/$roomId', extra: user);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalRequested = requests.fold(
      0.0,
      (total, r) => total + r.loanAmount,
    );
    final isOwnProfile = currentUserId == user.uid;
    final displayName = user.name.isNotEmpty ? user.name : 'Borrower';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'B';
    final cityText = user.city?.isNotEmpty == true
        ? user.city!
        : (requests.isNotEmpty ? requests.first.borrowerCity : 'India');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Custom Hero Sliver App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: AppIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
              bgColor: Colors.black26,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: BookmarkButton(
                  borrowerId: user.uid,
                  borrowerName: displayName,
                  borrowerCity: cityText,
                  isVerified: user.isVerified,
                  loanAmount: requests.isNotEmpty ? requests.first.loanAmount : null,
                  maxInterestRatePerMonth: requests.isNotEmpty ? requests.first.maxInterestRatePerMonth : null,
                  tenureMonths: requests.isNotEmpty ? requests.first.tenureMonths : null,
                  collateralType: requests.isNotEmpty ? requests.first.collateralType : null,
                  collateralValue: requests.isNotEmpty ? requests.first.collateralValue : null,
                  requestId: requests.isNotEmpty ? requests.first.id : null,
                  showBackground: true,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 36),
                    // Borrower Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.emeraldGradient,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: AppTextStyles.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 12),
                    Text(displayName, style: AppTextStyles.h2)
                        .animate()
                        .fadeIn(delay: 150.ms),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          cityText,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.isVerified) const VerifiedBadge(small: true),
                      ],
                    ).animate().fadeIn(delay: 250.ms),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Profile Details & Stats
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
                    _BorrowerStatCard(
                      icon: Icons.verified_user_rounded,
                      label: 'KYC Status',
                      value: user.kycStatus == KycStatus.verified
                          ? 'Verified'
                          : 'Pending',
                      color: user.kycStatus == KycStatus.verified
                          ? AppColors.emerald
                          : AppColors.warning,
                    ),
                    _BorrowerStatCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'Total Requests',
                      value: '${requests.length}',
                      color: AppColors.info,
                    ),
                    _BorrowerStatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Requested',
                      value: totalRequested > 0
                          ? AppFormatters.formatINRCompact(totalRequested)
                          : '₹0',
                      color: AppColors.gold,
                    ),
                    _BorrowerStatCard(
                      icon: Icons.star_rounded,
                      label: 'Profile Rating',
                      value: user.isVerified ? '4.8 ★' : 'New',
                      color: AppColors.emerald,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1, duration: 400.ms),

                const SizedBox(height: 20),

                // Contact / Action Button
                if (!isOwnProfile)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      onPressed: () => _startOrOpenChat(context),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: Text(
                        'Message $displayName',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.emerald.withValues(alpha: 0.4),
                      ),
                    ),
                  ).animate().fadeIn(delay: 180.ms),

                // Section Title
                Row(
                  children: [
                    Text('Loan Requests', style: AppTextStyles.h3),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Requests List
        if (requests.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No loan requests yet',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This borrower has not posted any active loan requests.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final req = requests[index];
                  return _BorrowerLoanRequestCard(
                    request: req,
                    onTap: () => context.push('/request/${req.id}'),
                  )
                      .animate()
                      .fadeIn(delay: (100 + (index * 60)).ms, duration: 350.ms)
                      .slideY(begin: 0.08, curve: Curves.easeOut);
                },
                childCount: requests.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }
}

class _BorrowerStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BorrowerStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BorrowerLoanRequestCard extends StatelessWidget {
  final LoanRequestModel request;
  final VoidCallback onTap;

  const _BorrowerLoanRequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = request.status == LoanRequestStatus.open
        ? AppColors.gold
        : request.status == LoanRequestStatus.matched
            ? AppColors.emerald
            : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Amount & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.emerald,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppFormatters.formatINR(request.loanAmount),
                          style: AppTextStyles.amountMedium.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TagChip(
                      label: request.status.name.toUpperCase(),
                      color: statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Key metrics row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TagChip(
                      label: '${request.tenureMonths} Months',
                      color: AppColors.textSecondary,
                    ),
                    TagChip(
                      label: '${request.maxInterestRatePerMonth}%/mo',
                      color: AppColors.warning,
                    ),
                    if (request.collateralType.isNotEmpty)
                      TagChip(
                        label: 'Collateral: ${request.collateralType}',
                        color: AppColors.info,
                      ),
                  ],
                ),

                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    request.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 10),

                // Bottom row: Date & View Details arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Posted ${AppFormatters.formatRelative(request.createdAt)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View Request',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.bold,
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
  }
}
