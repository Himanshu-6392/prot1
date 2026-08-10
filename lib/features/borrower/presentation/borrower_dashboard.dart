import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/glass_widgets.dart';
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

class BorrowerDashboard extends ConsumerStatefulWidget {
  const BorrowerDashboard({super.key});

  @override
  ConsumerState<BorrowerDashboard> createState() => _BorrowerDashboardState();
}

class _BorrowerDashboardState extends ConsumerState<BorrowerDashboard> {
  bool _requestsExpanded = true;
  static bool _hasNotifications = true;

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
                  child: _buildPortfolioCard(uid)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: _QuickActions()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: Padding(
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      child: SectionHeader(
                        title: 'Lenders Near You',
                        onSeeAll: () => context.go('/search'),
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
                  ),
                  SliverToBoxAdapter(
                    child: _NearbyLendersRow()
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                  ),
                ],
                SliverToBoxAdapter(
                  child: const _FinancialTipsRow()
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                ),
                SliverToBoxAdapter(
                  child: const MarketInsightsCard(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
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

  Widget _buildPortfolioCard(String userId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
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

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'YOUR PROFILE STATS',
                          style: AppTextStyles.tag.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text('Level 1', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const _TrustScoreGauge(score: 742), // 742 out of 1000
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              reqSnap.hasData ? '$activeCount' : '-',
                              style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 24),
                            ),
                            Text('Active', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              matchSnap.hasData ? '$matchedCount' : '-',
                              style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 24),
                            ),
                            Text('Matches', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Post New Request',
                        onPressed: () => context.push('/post-request'),
                        color: AppColors.emerald,
                        icon: const Icon(Icons.add_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatsRow extends ConsumerWidget {
  final String userId;
  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox(height: 115);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colRequests)
          .where('borrowerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        int activeLoans = 0;
        int completedDeals = 0;
        double totalRequested = 0;

        if (snap.hasData) {
          final docs = snap.data!.docs;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'open';
            final amount = (data['loanAmount'] ?? 0).toDouble();

            if (status == 'completed') {
              completedDeals++;
            } else if (status == 'open' ||
                status == 'matched' ||
                status == 'accepted') {
              activeLoans++;
              totalRequested += amount;
            }
          }
        }

        return SizedBox(
          height: 115,
          child: ListView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 12),
            children: [
              _StatCard(
                  label: 'Total Requested',
                  value: snap.hasData
                      ? AppFormatters.formatINR(totalRequested)
                      : '...',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.gold),
              _StatCard(
                  label: 'Active Requests',
                  value: snap.hasData ? '$activeLoans' : '...',
                  icon: Icons.bolt_rounded,
                  color: AppColors.goldLight),
              _StatCard(
                  label: 'Completed Deals',
                  value: snap.hasData ? '$completedDeals' : '...',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.emerald),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends ConsumerWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(sensitiveDataVisibleProvider);

    return GestureDetector(
      onTap: () {
        if (!isVisible) {
          showPinDialog(context, ref);
        }
      },
      child: NeumorphicContainer(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isVisible
                      ? Text(
                          value,
                          key: const ValueKey('visible'),
                          style: AppTextStyles.h1
                              .copyWith(fontSize: 32, height: 1),
                        )
                      : Row(
                          key: const ValueKey('hidden'),
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'â€¢â€¢â€¢â€¢',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 32,
                                height: 1,
                                color: AppColors.textPrimary.withOpacity(0.5),
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.lock_rounded,
                                size: 20,
                                color: AppColors.textPrimary.withOpacity(0.4)),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _QuickActions extends StatefulWidget {
  const _QuickActions({super.key});

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions> {
  static bool _matchesBadge = false;
  static bool _analyticsBadge = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillAction(
                context: context,
                icon: Icons.pending_actions_rounded,
                label: 'Matches',
                onTap: () async {
                  if (_matchesBadge) setState(() => _matchesBadge = false);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/match');
                },
                showBadge: _matchesBadge,
              ),
              Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.3)),
              _buildPillAction(
                context: context,
                icon: Icons.switch_account_rounded,
                label: 'Switch Role',
                onTap: () async {
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/auth/role-selection');
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
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MyRequestsSliver extends ConsumerWidget {
  final String userId;
  const _MyRequestsSliver({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colRequests)
            .where('borrowerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(children: [
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
                // â”€â”€ Tappable header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                                      color: statusColor.withOpacity(0.4)),
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _NearbyLendersRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLenders)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerBox(
                      width: double.infinity, height: 58, borderRadius: 14),
                ),
              ),
            ),
          );
        }

        var docs = snap.data!.docs.toList();
        docs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['businessName']?.toString().toLowerCase() != 'test';
        }).toList();

        docs.sort((a, b) {
          final aFeat =
              (a.data() as Map<String, dynamic>)['isFeatured'] == true ? 1 : 0;
          final bFeat =
              (b.data() as Map<String, dynamic>)['isFeatured'] == true ? 1 : 0;
          return bFeat.compareTo(aFeat);
        });
        if (docs.length > 5) docs = docs.sublist(0, 5);

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text('No lenders available near you right now.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 24),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _ProductLenderCard(data: data, id: docs[i].id)
                  .animate().fadeIn(duration: 300.ms, delay: (i * 80).ms).slideX(begin: 0.1, curve: Curves.easeOutBack);
            },
          ),
        );
      },
    );
  }
}

class _ProductLenderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const _ProductLenderCard({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    final name = data['businessName'] ?? 'Lender';
    final city = data['city'] ?? 'Nearby';
    
    final double maxLoan = (data['maxLoanAmount'] ?? 0).toDouble();
    final String limitText = maxLoan > 0 ? AppFormatters.formatINRCompact(maxLoan) : '₹5L';
    
    final double interestRate = (data['interestRatePerMonth'] ?? 0).toDouble();
    final String aprText = interestRate > 0 ? '$interestRate% APR' : '12.5% APR';
    
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
          onTap: () => context.push('/lender-profile/$id'),
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
                      name[0].toUpperCase(),
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
                        style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              city,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          aprText,
                          style: AppTextStyles.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.bold, fontSize: 10),
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
                    // Limit text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Up to', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
                        Text(limitText, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, height: 1.0, fontWeight: FontWeight.w900)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
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

// ──────────────────────────────────────────────
class _TrustScoreGauge extends StatelessWidget {
  final int score;
  const _TrustScoreGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 1000.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(120, 60), 
          painter: _TrustScorePainter(percentage: value),
          child: SizedBox(
            width: 120,
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  (value * 1000).toInt().toString(),
                  style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 24, height: 1.0),
                ),
                Text(
                  'Trust Score',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrustScorePainter extends CustomPainter {
  final double percentage;
  _TrustScorePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final startAngle = math.pi;
    final sweepAngle = math.pi;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFFF59E0B)], // Emerald to Gold
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle * percentage, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _TrustScorePainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

