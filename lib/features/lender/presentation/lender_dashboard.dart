import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import '../../../core/widgets/interactive_empty_state.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/widgets/market_insights_card.dart';
import '../../../models/user_model.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/pin_entry_dialog.dart';
import '../../../core/widgets/profile_stats_card.dart';
import '../../../core/widgets/financial_tips_row.dart';
import '../../../core/services/trust_score_service.dart';
import '../../../core/widgets/bookmark_button.dart';
import '../../../core/providers/saved_borrowers_provider.dart';

class LenderDashboard extends ConsumerStatefulWidget {
  const LenderDashboard({super.key});

  @override
  ConsumerState<LenderDashboard> createState() => _LenderDashboardState();
}

class _LenderDashboardState extends ConsumerState<LenderDashboard> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPinSetup());
  }

  void _checkPinSetup() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final security = ref.read(securityProvider);
    if (user != null && !security.isLoading && !security.isPinSet && mounted) {
      showPinDialog(context, ref, forceSetup: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 4.seconds),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 5.seconds, delay: 1.seconds),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    // Simulate refresh
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                    final double percentage = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
                    final isRefreshing = refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.armed;
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: isRefreshing
                              ? Icon(Icons.sync_rounded, color: AppColors.emerald, size: 24)
                                  .animate(onPlay: (c) => c.repeat())
                                  .rotate(duration: 1.seconds)
                              : Transform.rotate(
                                  angle: percentage * 2 * math.pi,
                                  child: Icon(Icons.sync_rounded, color: AppColors.emerald.withValues(alpha: percentage), size: 24),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(child: _LenderHeader(user: user)),
                SliverToBoxAdapter(
                    child: _LenderPortfolioCard(userId: user?.uid ?? '')),
                SliverToBoxAdapter(child: _ManageSection(userId: user?.uid ?? '')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                    child: SectionHeader(
                      title: 'Recommended Borrowers',
                      onSeeAll: () => context.push('/borrower-search'),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                ),
                _RecommendedBorrowersSliver(lenderId: user?.uid ?? ''),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                    child: SectionHeader(
                      title: 'Saved Borrowers',
                      onSeeAll: () => context.push('/saved-borrowers'),
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                ),
                _SavedBorrowersSliver(lenderId: user?.uid ?? ''),
                const SliverToBoxAdapter(
                  child: FinancialTipsRow(),
                ),
                const SliverToBoxAdapter(
                  child: MarketInsightsCard(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-offer'),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Manage Offer'),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _LenderHeader extends ConsumerWidget {
  final UserModel? user;
  const _LenderHeader({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final firstName =
        user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'Lender';
    final initial =
        (user?.name.isNotEmpty == true ? user!.name[0] : 'L').toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1,
                    )),
                Text(firstName,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.gold,
                      letterSpacing: -1,
                      height: 1.1,
                    )),
              ],
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
          ),

          const SizedBox(width: 16),
          // Notification Bell
          GestureDetector(
            onTap: () {
              context.push('/notifications');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds, curve: Curves.easeInOut),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(width: 8),
          
          // Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _LenderPortfolioCard extends ConsumerWidget {
  final String userId;
  const _LenderPortfolioCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox(height: 170);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colLenders)
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snap) {
          int activeOffers = 0;
          int totalMatches = 0;

          if (snap.hasData) {
            for (var doc in snap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['isActive'] == true) {
                activeOffers++;
              }
              totalMatches += ((d['matchedBorrowerIds'] as List?)?.length ?? 0);
            }
          }

          final breakdown = TrustScoreService.calculate(
            user: user,
            requestsCount: activeOffers,
            matchesCount: totalMatches,
          );

          return ProfileStatsCard(
            trustScore: breakdown.totalScore,
            badgeText: breakdown.badgeText,
            badgeIcon: breakdown.levelIcon,
            stat1Value: snap.hasData ? '$activeOffers' : '-',
            stat1Label: 'Active',
            stat2Value: snap.hasData ? '$totalMatches' : '-',
            stat2Label: 'Matches',
            buttonLabel: 'Create New Offer',
            onButtonPressed: () => context.push('/create-offer'),
            onTrustScoreTap: () => TrustScoreService.showBreakdownSheet(context, breakdown),
          );
        },
      ),
    );
  }
}



class _ManageSection extends ConsumerStatefulWidget {
  final String userId;
  const _ManageSection({required this.userId});

  @override
  ConsumerState<_ManageSection> createState() => _ManageSectionState();
}

class _ManageSectionState extends ConsumerState<_ManageSection> {
  static bool _browseBadge = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillAction(
                context: context,
                icon: Icons.receipt_long_rounded,
                label: 'My Requests',
                onTap: () async {
                  if (_browseBadge) setState(() => _browseBadge = false);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/my-requests');
                },
                showBadge: _browseBadge,
              ),
              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.receipt_long_rounded,
                label: 'My Offers',
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/match');
                },
              ),
              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.switch_account_rounded,
                label: 'Switch Role',
                onTap: () async {
                  final user = ref.read(currentUserProvider).valueOrNull;
                  if (user != null) {
                    await ref.read(firestoreProvider).collection('users').doc(user.uid).update({'role': UserRole.borrower.name});
                  }
                },
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildPillAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.7), size: 22),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _RecommendedBorrowersSliver extends ConsumerWidget {
  final String lenderId;
  const _RecommendedBorrowersSliver({required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colRequests)
            .orderBy('createdAt', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Column(
                children: [RequestCardShimmer(), RequestCardShimmer()]);
          }
          final allDocs = snap.data!.docs;
          final docs = allDocs
              .where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (data['borrowerName'] == 'Test User') return false; // HIDE DEMO REQUESTS
                if (data['borrowerId'] == lenderId) return false; // HIDE OWN REQUESTS
                final status = data['status'] ?? 'open';
                return status == 'open';
              })
              .toList();

          // Group by borrowerId (or borrowerName if id is empty)
          final Map<String, List<Map<String, dynamic>>> borrowerGroups = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            data['requestId'] = doc.id;
            final key = (data['borrowerId'] != null && data['borrowerId'].toString().isNotEmpty)
                ? data['borrowerId'].toString()
                : (data['borrowerName'] ?? doc.id).toString();
            borrowerGroups.putIfAbsent(key, () => []).add(data);
          }

          if (borrowerGroups.isEmpty) {
            return const InteractiveEmptyState(
              title: 'No recommended borrowers',
              subtitle: 'Active borrowers looking for loans will appear here.',
              lottieUrl: 'https://lottie.host/80456184-e3fb-46bf-85f9-2169eb7412f8/Q9i9tA8Y28.json',
            );
          }

          final borrowerList = borrowerGroups.entries.take(5).toList();

          return Column(
            children: borrowerList.map((entry) {
              final bId = entry.key;
              final reqList = entry.value;
              final latestReq = reqList.first;

              return _RecommendedBorrowerCard(
                borrowerId: bId,
                data: latestReq,
                totalRequestsCount: reqList.length,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _RecommendedBorrowerCard extends StatelessWidget {
  final String borrowerId;
  final Map<String, dynamic> data;
  final int totalRequestsCount;

  const _RecommendedBorrowerCard({
    required this.borrowerId,
    required this.data,
    required this.totalRequestsCount,
  });

  @override
  Widget build(BuildContext context) {
    final borrowerName = (data['borrowerName'] ?? 'Borrower').toString();
    final city = (data['borrowerCity'] ?? 'India').toString();
    final double loanAmount = (data['loanAmount'] ?? 0).toDouble();
    final tenure = data['tenureMonths'] ?? 0;
    final maxRate = data['maxInterestRatePerMonth'] ?? '-';
    final collateralType = (data['collateralType'] ?? '').toString();
    final isVerified = data['isVerified'] == true;
    final initial = borrowerName.isNotEmpty ? borrowerName[0].toUpperCase() : 'B';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                // Top Row: Avatar, Name, Location & Requests Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
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
                    // Badge: Total Requests
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 13, color: AppColors.emerald),
                          const SizedBox(width: 4),
                          Text(
                            '$totalRequestsCount Req',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    BookmarkButton(
                      borrowerId: borrowerId,
                      borrowerName: borrowerName,
                      borrowerCity: city,
                      isVerified: isVerified,
                      loanAmount: loanAmount,
                      maxInterestRatePerMonth: data['maxInterestRatePerMonth'] != null ? (data['maxInterestRatePerMonth'] as num).toDouble() : null,
                      tenureMonths: tenure is int ? tenure : null,
                      collateralType: collateralType.isNotEmpty ? collateralType : null,
                      collateralValue: data['collateralValue'] != null ? (data['collateralValue'] as num).toDouble() : null,
                      requestId: (data['requestId'] ?? '').toString().isNotEmpty ? data['requestId'].toString() : null,
                      size: 20,
                      padding: const EdgeInsets.all(6),
                      showBackground: true,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Loan details badge container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Requested Loan',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
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
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
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
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatTenure(tenure),
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

                // Bottom row: Collateral Tag & "View Profile" CTA
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
                          'View Borrower Profile',
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOut);
  }
}

// ──────────────────────────────────────────────
// Saved Borrowers Sliver & Card for Home Screen
// ──────────────────────────────────────────────
class _SavedBorrowersSliver extends ConsumerWidget {
  final String lenderId;
  const _SavedBorrowersSliver({required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedListAsync = ref.watch(savedBorrowersListProvider);

    return savedListAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              RequestCardShimmer(),
              SizedBox(height: 12),
              RequestCardShimmer(),
            ],
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to load saved borrowers',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bookmark_outline_rounded,
                          size: 26,
                          color: AppColors.emerald,
                        ),
                      ),
                    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 14),
                    Text(
                      'No saved borrowers yet',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Save borrowers you're interested in to find their profiles and loan requests quickly.",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Explore Borrowers',
                      icon: const Icon(Icons.explore_rounded, size: 16),
                      height: 40,
                      width: 180,
                      color: AppColors.emerald,
                      onPressed: () => context.push('/borrower-search'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
            ),
          );
        }

        // Show a maximum of 2–3 saved borrower cards on the home screen
        final displayItems = items.take(3).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = displayItems[index];
              final borrowerId = (item['borrowerId'] ?? '').toString();

              return _SavedBorrowerHomeCard(
                borrowerId: borrowerId,
                savedData: item,
              );
            },
            childCount: displayItems.length,
          ),
        );
      },
    );
  }
}

class _SavedBorrowerHomeCard extends ConsumerWidget {
  final String borrowerId;
  final Map<String, dynamic> savedData;

  const _SavedBorrowerHomeCard({
    required this.borrowerId,
    required this.savedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrowerName = (savedData['borrowerName'] ?? 'Borrower').toString();
    final city = (savedData['borrowerCity'] ?? 'India').toString();
    final isVerified = savedData['isVerified'] == true;
    final initial = borrowerName.isNotEmpty ? borrowerName[0].toUpperCase() : 'B';

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
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                    // Top Row: Avatar, Name & City, Open Requests Tag, Bookmark Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
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

                        // Active Requests Pill
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
                          size: 20,
                          padding: const EdgeInsets.all(6),
                          showBackground: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Compact Summary or Inactive Status
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

                    // Bottom Row: Collateral Badge & Chevron / View Profile
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
                              'View Borrower Profile',
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
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOut);
      },
    );
  }
}

