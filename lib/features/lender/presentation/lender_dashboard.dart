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
import '../../../core/widgets/role_switch_sheet.dart';
import '../../../core/services/trust_score_service.dart';

class LenderDashboard extends ConsumerStatefulWidget {
  const LenderDashboard({super.key});

  @override
  ConsumerState<LenderDashboard> createState() => _LenderDashboardState();
}

class _LenderDashboardState extends ConsumerState<LenderDashboard> {
  bool _requestsExpanded = true;

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
                      title: 'Incoming Requests',
                      isExpandable: true,
                      isExpanded: _requestsExpanded,
                      onToggle: () => setState(() => _requestsExpanded = !_requestsExpanded),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                ),
                if (_requestsExpanded) _IncomingRequestsSliver(lenderId: user?.uid ?? ''),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    child: SectionHeader(
                      title: 'Borrowers Near You',
                      onSeeAll: () => context.push('/borrower-search'),
                    ),
                  ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: _NearbyBorrowersRow(lenderId: user?.uid ?? '')
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                ),
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
                    color: Colors.black.withOpacity(0.05),
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
              Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.receipt_long_rounded,
                label: 'My Offers',
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/match');
                },
              ),
              Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
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
                  Icon(icon, color: AppColors.textPrimary.withOpacity(0.7), size: 22),
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



class _IncomingRequestsSliver extends ConsumerWidget {
  final String lenderId;
  const _IncomingRequestsSliver({required this.lenderId});

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
              .take(10)
              .toList();

          if (docs.isEmpty) {
            return const InteractiveEmptyState(
              title: 'No open requests',
              subtitle: 'New borrower requests will appear here.',
              lottieUrl: 'https://lottie.host/80456184-e3fb-46bf-85f9-2169eb7412f8/Q9i9tA8Y28.json',
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

class _IncomingCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String id;
  const _IncomingCard({required this.data, required this.id});

  @override
  State<_IncomingCard> createState() => _IncomingCardState();
}

class _IncomingCardState extends State<_IncomingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.gold;
    final loanAmount = (widget.data['loanAmount'] ?? 0).toDouble();
    final tenure = widget.data['tenureMonths'] ?? 0;
    final maxRate = widget.data['maxInterestRatePerMonth'] ?? '-';
    final collateralType = widget.data['collateralType'] ?? '';
    final borrowerName = widget.data['borrowerName'] ?? 'Unknown Borrower';
    final description = widget.data['description'] ?? '';
    final city = widget.data['borrowerCity'] ?? '';
    final collateralValue = (widget.data['collateralValue'] ?? 0).toDouble();
    
    // Parse createdAt
    DateTime? getSafeTime(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      try {
        return val.toDate(); // Handles Timestamp
      } catch (_) {
        return null;
      }
    }
    final createdAt = getSafeTime(widget.data['createdAt']) ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Dismissible(
        key: Key(widget.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) {
          FirebaseFirestore.instance.collection(AppConstants.colRequests).doc(widget.id).delete();
        },
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          elevation: _expanded ? 4 : 1,
          shadowColor: _expanded ? statusColor.withOpacity(0.15) : Colors.black12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _expanded
                    ? statusColor.withOpacity(0.35)
                    : AppColors.border.withOpacity(0.4),
                width: _expanded ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tappable header ────────────────────────
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    splashColor: statusColor.withOpacity(0.08),
                    highlightColor: statusColor.withOpacity(0.04),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
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
                                  AppFormatters.formatINR(loanAmount),
                                  style: AppTextStyles.amountMedium
                                      .copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${AppFormatters.formatTenure(tenure)} · $maxRate%/mo',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TagChip(
                              label: (widget.data['status'] ?? 'OPEN').toString().toUpperCase(),
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

                  // ── Expandable body ───────────────────────────
                  if (_expanded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border.withOpacity(0.5)),
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
                                        label: collateralType,
                                        color: AppColors.info),
                                    TagChip(
                                        label: AppFormatters.formatTenure(tenure),
                                      color: AppColors.textSecondary),
                                  TagChip(
                                      label: '${maxRate}%/mo',
                                      color: AppColors.warning),
                                  if (widget.data['isVerified'] == true)
                                    TagChip(
                                        label: '✓ Verified',
                                        color: AppColors.emerald),
                                ],
                              ),

                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  description,
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
                                  Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 13),
                                  const SizedBox(width: 3),
                                  Flexible(child: Text(borrowerName, style: AppTextStyles.caption)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.location_on_rounded,
                                      color: AppColors.textMuted, size: 13),
                                  const SizedBox(width: 3),
                                  Flexible(
                                      child: Text(city,
                                          style: AppTextStyles.caption)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.account_balance_wallet_outlined,
                                      color: AppColors.textMuted, size: 13),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Collateral: ${AppFormatters.formatINR(collateralValue)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                      AppFormatters.formatRelative(createdAt),
                                      style: AppTextStyles.caption),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // View details / Respond button
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: 'Respond to Request',
                                  onPressed: () => context.push('/request/${widget.id}'),
                                  color: AppColors.gold,
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
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

// ──────────────────────────────────────────────
// Borrowers Near You Row & Card
// ──────────────────────────────────────────────
class _NearbyBorrowersRow extends ConsumerWidget {
  final String lenderId;
  const _NearbyBorrowersRow({required this.lenderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colRequests)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 24),
              itemBuilder: (_, __) => const ShimmerBox(width: 300, height: 100, borderRadius: 12),
            ),
          );
        }

        var docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          if (data['borrowerName'] == 'Test User') return false;
          if (lenderId.isNotEmpty && data['borrowerId'] == lenderId) return false;
          final status = data['status'] ?? 'open';
          return status == 'open';
        }).toList();

        final List<Map<String, dynamic>> items;
        if (docs.isNotEmpty) {
          items = docs.map((d) {
            final map = Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
            map['requestId'] = d.id;
            return map;
          }).toList();
        } else {
          items = [
            {
              'requestId': '',
              'borrowerName': 'Aarav Sharma',
              'borrowerCity': 'Kanpur',
              'loanAmount': 35000.0,
              'maxInterestRatePerMonth': 2.0,
              'collateralType': 'Gold',
              'isVerified': true,
            },
            {
              'requestId': '',
              'borrowerName': 'Priya Patel',
              'borrowerCity': 'Lucknow',
              'loanAmount': 50000.0,
              'maxInterestRatePerMonth': 2.5,
              'collateralType': 'Laptop',
              'isVerified': true,
            },
            {
              'requestId': '',
              'borrowerName': 'Rahul Verma',
              'borrowerCity': 'Kanpur',
              'loanAmount': 20000.0,
              'maxInterestRatePerMonth': 1.8,
              'collateralType': 'Bike',
              'isVerified': false,
            },
          ];
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemBuilder: (context, i) {
              final item = items[i];
              return _ProductBorrowerCard(data: item)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (i * 80).ms)
                  .slideX(begin: 0.1, curve: Curves.easeOutBack);
            },
          ),
        );
      },
    );
  }
}

class _ProductBorrowerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductBorrowerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = (data['borrowerName'] ?? 'Borrower').toString();
    final city = (data['borrowerCity'] ?? 'Nearby').toString();
    final requestId = (data['requestId'] ?? '').toString();

    final double loanAmount = (data['loanAmount'] ?? 0).toDouble();
    final String limitText = loanAmount > 0
        ? AppFormatters.formatINRCompact(loanAmount)
        : '₹25K';

    final double interestRate =
        (data['maxInterestRatePerMonth'] ?? 0).toDouble();
    final String aprText = interestRate > 0
        ? '$interestRate% APR'
        : '2% APR';

    // Subtle colors for avatar tint
    final colorHash = name.length % 3;
    final Color tintColor = colorHash == 0
        ? const Color(0xFF6366F1) // Indigo
        : colorHash == 1
            ? const Color(0xFF10B981) // Emerald
            : const Color(0xFFF59E0B); // Amber

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (requestId.isNotEmpty) {
              context.push('/request/$requestId');
            } else {
              context.push('/borrower-search');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tintColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'B',
                        style: AppTextStyles.h2.copyWith(color: tintColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            aprText,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side (Limit & Action)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Up to',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted, fontSize: 10)),
                          Text(limitText,
                              style: AppTextStyles.h3.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

