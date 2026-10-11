import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/interactive_empty_state.dart';
import '../../../core/widgets/market_insights_card.dart';
import 'dart:ui';
import 'dart:async';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/pin_entry_dialog.dart';
import 'dart:math' as math;
import '../../../models/user_model.dart';
import '../../../models/loan_request_model.dart';
import '../../../core/widgets/profile_stats_card.dart';
import '../../../core/services/trust_score_service.dart';
import '../../../core/widgets/lender_bookmark_button.dart';
import '../../../core/providers/saved_lenders_provider.dart';

class BorrowerDashboard extends ConsumerStatefulWidget {
  const BorrowerDashboard({super.key});

  @override
  ConsumerState<BorrowerDashboard> createState() => _BorrowerDashboardState();
}

class _BorrowerDashboardState extends ConsumerState<BorrowerDashboard> {
  bool _requestsExpanded = true;
  static bool _hasNotifications = true;
  final GlobalKey _myRequestsKey = GlobalKey();

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
    final uid = user?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background Gradient Mesh — gently pulsing blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withValues(alpha: 0.06),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 4000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1.05, 1.05), end: const Offset(0.95, 0.95), duration: 5000.ms, curve: Curves.easeInOut),
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
                    HapticFeedback.mediumImpact();
                    await Future.delayed(const Duration(milliseconds: 1500));
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
                SliverToBoxAdapter(child: _buildHeader(context, user)),
                SliverToBoxAdapter(
                  child: _buildPortfolioCard(uid, user)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: _QuickActions(onMyRequestsTap: () {
                    Scrollable.ensureVisible(_myRequestsKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                  })
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    key: _myRequestsKey,
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                    child: SectionHeader(
                      title: 'My Requests',
                      isExpandable: true,
                      isExpanded: _requestsExpanded,
                      onToggle: () => setState(() => _requestsExpanded = !_requestsExpanded),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                ),
                if (_requestsExpanded) _MyRequestsSliver(userId: uid),
                if (user?.role != UserRole.lender) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                      child: SectionHeader(
                        title: 'Recommended Lenders',
                        onSeeAll: () => context.push('/search'),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                  ),
                  const _RecommendedLendersSliver(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: SectionHeader(
                        title: 'Saved Lenders',
                        onSeeAll: () => context.push('/saved-lenders'),
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                  ),
                  const _SavedLendersSliver(),
                ],
                SliverToBoxAdapter(
                  child: const _FinancialTipsRow()
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                ),
                const SliverToBoxAdapter(
                  child: MarketInsightsCard(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final firstName =
        user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'User';
    final initial =
        (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      firstName,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.gold,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
              ),

              const SizedBox(width: 16),
              // Notification Bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                    onPressed: () {
                      if (_hasNotifications) {
                        setState(() => _hasNotifications = false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You have no new notifications')),
                        );
                      }
                    },
                  ),
                  if (_hasNotifications)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.7, end: 1.2, duration: 1.seconds),
                    ),
                ],
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
                          foreground: Paint()
                            ..shader = AppColors.goldGradient
                                .createShader(const Rect.fromLTWH(0.0, 0.0, 50.0, 50.0)),
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(String userId, UserModel? user) {
    if (userId.isEmpty) {
      final breakdown = TrustScoreService.calculate(user: user);
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ProfileStatsCard(
          trustScore: breakdown.totalScore,
          badgeText: breakdown.badgeText,
          badgeIcon: breakdown.levelIcon,
          stat1Value: '0',
          stat1Label: 'Active',
          stat2Value: '0',
          stat2Label: 'Matches',
          buttonLabel: 'Post New Request',
          onButtonPressed: () => context.push('/post-request'),
          onTrustScoreTap: () => TrustScoreService.showBreakdownSheet(context, breakdown),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colCollateral)
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, colSnap) {
          final colCount = colSnap.hasData ? colSnap.data!.docs.length : 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colMatches)
                .where('borrowerId', isEqualTo: userId)
                .snapshots(),
            builder: (context, matchSnap) {
              int matchedCount = matchSnap.hasData ? matchSnap.data!.docs.length : 0;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colRequests)
                    .where('borrowerId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, reqSnap) {
                  int activeCount = 0;

                  if (reqSnap.hasData) {
                    for (var doc in reqSnap.data!.docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = d['status'] ?? 'open';
                      if (status == 'open') {
                        activeCount++;
                      }
                    }
                  }

                  final breakdown = TrustScoreService.calculate(
                    user: user,
                    requestsCount: activeCount,
                    collateralCount: colCount,
                    matchesCount: matchedCount,
                  );

                  return ProfileStatsCard(
                    trustScore: breakdown.totalScore,
                    badgeText: breakdown.badgeText,
                    badgeIcon: breakdown.levelIcon,
                    stat1Value: reqSnap.hasData ? '$activeCount' : '-',
                    stat1Label: 'Active',
                    stat2Value: matchSnap.hasData ? '$matchedCount' : '-',
                    stat2Label: 'Matches',
                    buttonLabel: 'Post New Request',
                    onButtonPressed: () => context.push('/post-request'),
                    onTrustScoreTap: () => TrustScoreService.showBreakdownSheet(context, breakdown),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickActions extends ConsumerStatefulWidget {
  final VoidCallback onMyRequestsTap;
  const _QuickActions({required this.onMyRequestsTap});

  @override
  ConsumerState<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends ConsumerState<_QuickActions> {
  static bool _matchesBadge = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(30),
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
                  if (_matchesBadge) setState(() => _matchesBadge = false);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/my-requests');
                },
                showBadge: _matchesBadge,
              ),
              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.switch_account_rounded,
                label: 'Switch Role',
                onTap: () async {
                  final user = ref.read(currentUserProvider).valueOrNull;
                  if (user != null) {
                    await ref.read(firestoreProvider).collection('users').doc(user.uid).update({'role': UserRole.lender.name});
                  }
                },
              ),
              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.calculate_outlined,
                label: 'Rate Calc',
                onTap: () => context.push('/calculator'),
              ),
            ],
          ),
        ),
      )))),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
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
          borderRadius: BorderRadius.circular(30), // Keeps ripple contained to the section
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 18, color: AppColors.textPrimary),
                    if (showBadge)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.7, end: 1.2, duration: 1.seconds),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MyRequestsSliver extends ConsumerWidget {
  final String userId;
  const _MyRequestsSliver({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colRequests)
            .where('borrowerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Column(children: [
              RequestCardShimmer(),
              RequestCardShimmer(),
            ]);
          }
          var docs = snap.data!.docs.toList();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['borrowerName'] != 'Test User';
          }).toList();
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            DateTime? getSafeTime(Map<String, dynamic> data) {
              final val = data['createdAt'];
              if (val is Timestamp) return val.toDate();
              if (val is String) return DateTime.tryParse(val);
              return null;
            }

            final aTime = getSafeTime(aData);
            final bTime = getSafeTime(bData);

            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          if (docs.length > 5) docs = docs.sublist(0, 5);

          if (docs.isEmpty) {
            return const InteractiveEmptyState(
              title: 'No requests yet',
              subtitle: 'Post your first loan request to get started.',
              lottieUrl: 'assets/animations/onboarding_2.json',
            );
          }
          return Column(
            children: docs.map((d) {
              final req = LoanRequestModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id);
              return _RequestCard(key: ValueKey(req.id), request: req);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final LoanRequestModel request;
  const _RequestCard({super.key, required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;

  Color _statusColor(LoanRequestStatus s) => switch (s) {
        LoanRequestStatus.open => AppColors.gold,
        LoanRequestStatus.matched => AppColors.info,
        LoanRequestStatus.accepted => AppColors.emerald,
        LoanRequestStatus.completed => AppColors.success,
        LoanRequestStatus.cancelled => AppColors.error,
        LoanRequestStatus.expired => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final statusColor = _statusColor(req.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        elevation: _expanded ? 4 : 1,
        shadowColor: _expanded ? statusColor.withValues(alpha: 0.15) : Colors.black12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _expanded
                  ? statusColor.withValues(alpha: 0.35)
                  : AppColors.border.withValues(alpha: 0.4),
              width: _expanded ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tappable header ─────────────────────────────
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  splashColor: statusColor.withValues(alpha: 0.08),
                  highlightColor: statusColor.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long_rounded,
                              color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppFormatters.formatINR(req.loanAmount),
                                style: AppTextStyles.amountMedium
                                    .copyWith(fontSize: 17),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${AppFormatters.formatTenure(req.tenureMonths)} Â· ${req.maxInterestRatePerMonth}%/mo',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TagChip(
                            label: req.status.name.toUpperCase(),
                            color: statusColor),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.expand_more_rounded,
                                color: AppColors.textPrimary.withValues(alpha: 0.7), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // â”€â”€ Expandable body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (_expanded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border.withValues(alpha: 0.5)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TagChip(
                                    label: req.collateralType,
                                    color: AppColors.info),
                                TagChip(
                                    label: AppFormatters.formatTenure(
                                        req.tenureMonths),
                                    color: AppColors.textSecondary),
                                TagChip(
                                    label: '${req.maxInterestRatePerMonth}%/mo',
                                    color: AppColors.warning),
                                if (req.isVerified)
                                  TagChip(
                                      label: 'âœ“ Verified',
                                      color: AppColors.emerald),
                              ],
                            ),

                            if (req.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                req.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 12),

                            // Meta row
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: AppColors.textMuted, size: 13),
                                const SizedBox(width: 3),
                                Flexible(
                                    child: Text(req.borrowerCity,
                                        style: AppTextStyles.caption)),
                                const SizedBox(width: 10),
                                Icon(Icons.account_balance_wallet_outlined,
                                    color: AppColors.textMuted, size: 13),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Collateral: ${AppFormatters.formatINR(req.collateralValue)}',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                    AppFormatters.formatRelative(req.createdAt),
                                    style: AppTextStyles.caption),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // View details button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/request/${req.id}'),
                                icon: const Icon(Icons.open_in_new_rounded,
                                    size: 16),
                                label: const Text('View Full Details'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor,
                                  side: BorderSide(
                                      color: statusColor.withValues(alpha: 0.4)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.08, end: 0);
  }
}

// ──────────────────────────────────────────────
// Recommended Lenders Sliver & Card
// ──────────────────────────────────────────────
class _RecommendedLendersSliver extends ConsumerWidget {
  const _RecommendedLendersSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLenders)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
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
          );
        }

        var docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final name = data['businessName']?.toString().toLowerCase() ?? '';
          return name != 'test' && name.isNotEmpty;
        }).toList();

        // Sort featured first, then by rating
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aFeat = aData['isFeatured'] == true ? 1 : 0;
          final bFeat = bData['isFeatured'] == true ? 1 : 0;
          if (bFeat != aFeat) return bFeat.compareTo(aFeat);
          final aRating = (aData['rating'] ?? 0).toDouble();
          final bRating = (bData['rating'] ?? 0).toDouble();
          return bRating.compareTo(aRating);
        });

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'No lenders available right now.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }

        // Show top 3 recommended lenders
        final displayDocs = docs.take(3).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final d = displayDocs[i];
              final data = d.data() as Map<String, dynamic>;
              return _RecommendedLenderCard(
                lenderId: d.id,
                data: data,
              );
            },
            childCount: displayDocs.length,
          ),
        );
      },
    );
  }
}

class _RecommendedLenderCard extends StatelessWidget {
  final String lenderId;
  final Map<String, dynamic> data;

  const _RecommendedLenderCard({
    required this.lenderId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['businessName'] ?? 'Lender').toString();
    final city = (data['city'] ?? 'India').toString();
    final isVerified = data['isVerified'] == true;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'L';

    final double maxLoan = (data['maxLoanAmount'] ?? 0).toDouble();
    final double minLoan = (data['minLoanAmount'] ?? 0).toDouble();
    final double rate = (data['interestRatePerMonth'] ?? 0).toDouble();
    final int tenure = (data['maxTenureMonths'] ?? 0).toInt();
    final collaterals = (data['acceptedCollateral'] is List)
        ? (data['acceptedCollateral'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final String collateralStr = collaterals.isNotEmpty ? collaterals.take(2).join(', ') : '';

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
            context.push('/lender-profile/$lenderId');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Name, City, Active Tag, Bookmark
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
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
                                  name,
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

                    // Badge: Limit / Active
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
                          Icon(Icons.account_balance_rounded,
                              size: 13, color: AppColors.emerald),
                          const SizedBox(width: 4),
                          Text(
                            maxLoan > 0 ? AppFormatters.formatINRCompact(maxLoan) : 'Active',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    LenderBookmarkButton(
                      lenderId: lenderId,
                      businessName: name,
                      city: city,
                      isVerified: isVerified,
                      maxLoanAmount: maxLoan,
                      minLoanAmount: minLoan,
                      interestRatePerMonth: rate,
                      maxTenureMonths: tenure,
                      acceptedCollateral: collaterals,
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
                          Text('Available Loan',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
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
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
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
                          Text('Max Tenure',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            tenure > 0
                                ? AppFormatters.formatTenure(tenure)
                                : '12 mos',
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

                // Bottom row: Collateral Tag & "View Lender Profile" CTA
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOut);
  }
}

// ──────────────────────────────────────────────
// Saved Lenders Sliver & Card for Home Screen
// ──────────────────────────────────────────────
class _SavedLendersSliver extends ConsumerWidget {
  const _SavedLendersSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedListAsync = ref.watch(savedLendersListProvider);

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
                    'Unable to load saved lenders',
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
                      'No saved lenders yet',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Save lenders you're interested in to find their profiles and loan offers quickly.",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Explore Lenders',
                      icon: const Icon(Icons.explore_rounded, size: 16),
                      height: 40,
                      width: 180,
                      color: AppColors.emerald,
                      onPressed: () => context.push('/search'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut),
            ),
          );
        }

        // Show a maximum of 2–3 saved lender cards on the home screen
        final displayItems = items.take(3).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = displayItems[index];
              final lenderId = (item['lenderId'] ?? '').toString();

              return _SavedLenderHomeCard(
                lenderId: lenderId,
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

class _SavedLenderHomeCard extends ConsumerWidget {
  final String lenderId;
  final Map<String, dynamic> savedData;

  const _SavedLenderHomeCard({
    required this.lenderId,
    required this.savedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessName = (savedData['businessName'] ?? 'Lender').toString();
    final city = (savedData['city'] ?? 'India').toString();
    final isVerified = savedData['isVerified'] == true;
    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'L';

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
        final String collateralStr = collaterals.isNotEmpty ? collaterals.take(2).join(', ') : '';

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
                context.push('/lender-profile/$lenderId');
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar, Name & City, Tag, Bookmark Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
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

                        // Active Lender Tag
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
                          size: 20,
                          padding: const EdgeInsets.all(6),
                          showBackground: true,
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

                    // Bottom Row: Collateral Badge & Chevron / View Profile
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
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOut);
      },
    );
  }
}


// ──────────────────────────────────────────────
class _FinancialTipsRow extends StatefulWidget {
  const _FinancialTipsRow();

  @override
  State<_FinancialTipsRow> createState() => _FinancialTipsRowState();
}

class _FinancialTipsRowState extends State<_FinancialTipsRow> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!_scrollController.hasClients) return;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      if (maxScroll == 0) return; // Not enough content to scroll

      // Card width is 260 + 16 (separator) = 276
      final targetScroll = currentScroll + 276.0;
      
      if (targetScroll > maxScroll) {
        // Rewind to start
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      } else {
        _scrollController.animateTo(targetScroll, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Boost Trust Score',
        'desc': 'Verify your income to unlock lower rates.',
        'icon': Icons.trending_up_rounded,
        'colors': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
      },
      {
        'title': 'Collateral Types',
        'desc': 'Using digital gold drops rates by 2%.',
        'icon': Icons.diamond_rounded,
        'colors': [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
      },
      {
        'title': 'Fast Matching',
        'desc': 'Complete your profile to get matches 3x faster.',
        'icon': Icons.bolt_rounded,
        'colors': [const Color(0xFF10B981), const Color(0xFF3B82F6)]
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 16, 16),
            child: SectionHeader(title: 'Financial Tips', isExpandable: false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final colors = tips[i]['colors'] as List<Color>;
                return Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(tips[i]['icon'] as IconData,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tips[i]['title'] as String,
                              style: AppTextStyles.h4.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tips[i]['desc'] as String,
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(
                    begin: const Offset(0.9, 0.9),
                    duration: 400.ms,
                    delay: (i * 100).ms,
                    curve: Curves.easeOutBack);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

