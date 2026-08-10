import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'dart:ui';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/pin_entry_dialog.dart';
import '../../../models/user_model.dart';
import '../../../models/loan_request_model.dart';

class BorrowerDashboard extends ConsumerStatefulWidget {
  const BorrowerDashboard({super.key});

  @override
  ConsumerState<BorrowerDashboard> createState() => _BorrowerDashboardState();
}

class _BorrowerDashboardState extends ConsumerState<BorrowerDashboard> {
  bool _requestsExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check once after the first frame whether the user needs to set a PIN
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
            ),
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
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── App Bar ─────────────────────────
                SliverToBoxAdapter(child: _buildHeader(context, user)),

                // ─── Portfolio Hero Card ─────────────
                SliverToBoxAdapter(child: _buildPortfolioCard(uid)),

                // ─── Quick Actions ──────────────────
                SliverToBoxAdapter(child: _QuickActions()),

                // ─── My Requests ───────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                    child: SectionHeader(
                      title: 'My Requests',
                      isExpandable: true,
                      isExpanded: _requestsExpanded,
                      onToggle: () =>
                          setState(() => _requestsExpanded = !_requestsExpanded),
                    ),
                  ),
                ),
                if (_requestsExpanded) _MyRequestsSliver(userId: uid),

                // ─── Nearby Lenders ────────────────
                if (user?.role != UserRole.lender) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                      child: SectionHeader(
                          title: 'Lenders Near You',
                          onSeeAll: () => context.go('/search')),
                    ),
                  ),
                  SliverToBoxAdapter(child: _NearbyLendersRow()),
                ],



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
      child: Row(
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          reqSnap.hasData ? '$activeCount' : '-',
                          style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text('Active', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
                    Column(
                      children: [
                        Text(
                          matchSnap.hasData ? '$matchedCount' : '-',
                          style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text('Matches', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
                    Column(
                      children: [
                        Text(
                          '124',
                          style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text('Views', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
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

// ──────────────────────────────────────────────
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
                              '••••',
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

// ──────────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isVerified = user?.isVerified == true;

    void handlePostRequest() {
      if (!isVerified) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppColors.surfaceAlt,
            title: Text('Verification Required', style: AppTextStyles.h3),
            content: Text(
                'You must complete KYC verification before posting a loan request.',
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
                        color: AppColors.gold, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        context.push('/post-request');
      }
    }

    final actions = [
      _Action('Find Lenders', Icons.search_rounded, AppColors.textPrimary, false,
          () => context.go('/search')),
      _Action('Post Request', Icons.add_circle_rounded, Colors.white, true,
          handlePostRequest),
      _Action('Matches', Icons.handshake_rounded, AppColors.textPrimary, false,
          () => context.push('/match')),
      _Action('Chat', Icons.chat_bubble_rounded, AppColors.textPrimary, false,
          () => context.push('/chat')),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions.map((a) => _QuickActionBtn(action: a)).toList(),
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isPrimary;
  final VoidCallback onTap;
  const _Action(this.label, this.icon, this.iconColor, this.isPrimary, this.onTap);
}

class _QuickActionBtn extends StatelessWidget {
  final _Action action;
  const _QuickActionBtn({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: action.isPrimary 
                    ? AppColors.emerald 
                    : AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: action.isPrimary 
                    ? null 
                    : Border.all(color: AppColors.border.withValues(alpha: 0.3), width: 1),
                boxShadow: action.isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Center(
                child: Icon(action.icon, color: action.iconColor, size: 24),
              ),
            ).animate().scale(
                begin: const Offset(0.9, 0.9),
                curve: Curves.easeOutBack,
                duration: 400.ms),
            const SizedBox(height: 10),
            Text(
              action.label,
              style: AppTextStyles.caption.copyWith(
                  color: action.isPrimary ? AppColors.textPrimary : AppColors.textSecondary, 
                  fontWeight: action.isPrimary ? FontWeight.w700 : FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────


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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_outlined, size: 22, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No requests yet', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 2),
                          Text('Post your first loan request above.', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                // ── Tappable header ─────────────────────────
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
                                '${AppFormatters.formatTenure(req.tenureMonths)} · ${req.maxInterestRatePerMonth}%/mo',
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
                          child: Icon(Icons.expand_more_rounded,
                              color: AppColors.textMuted, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expandable body ──────────────────────────
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
                                      label: '✓ Verified',
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

// ──────────────────────────────────────────────
class _NearbyLendersRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLenders)
          .where('isActive', isEqualTo: true)
          // .orderBy('isFeatured', descending: true)
          // .limit(6)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) =>
                  const ShimmerBox(width: 160, height: 160, borderRadius: 16),
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
        if (docs.length > 6) docs = docs.sublist(0, 6);

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No lenders available near you right now.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => context.push('/lender-profile/${docs[i].id}'),
                child: NeumorphicContainer(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                              child: Text(
                            (data['businessName'] ?? 'L')[0].toUpperCase(),
                            style:
                                AppTextStyles.h4.copyWith(color: Colors.white),
                          )),
                        ),
                        const Spacer(),
                        if (data['isVerified'] == true)
                          Icon(Icons.verified_rounded,
                              color: AppColors.emerald, size: 16),
                      ]),
                      const SizedBox(height: 10),
                      Text(data['businessName'] ?? '',
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(data['city'] ?? '', style: AppTextStyles.caption),
                      const Spacer(),
                      Text(
                        '${data['interestRatePerMonth'] ?? '-'}% / mo',
                        style: AppTextStyles.amountSmall.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


