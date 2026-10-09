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
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/market_insights_card.dart';
import '../../../models/user_model.dart';
import '../../../core/providers/security_provider.dart';
import '../../../core/widgets/pin_entry_dialog.dart';

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
                    padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                    child: SectionHeader(
                      title: 'Incoming Requests',
                      onSeeAll: () => context.push('/borrower-search'),
                    ),
                  ),
                ),
                _IncomingRequestsSliver(lenderId: user?.uid ?? ''),
                SliverToBoxAdapter(
                  child: const MarketInsightsCard(),
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
                      color: AppColors.emerald,
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colLenders)
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snap) {
          int activeOffers = 0;
          double availableCapital = 0;
          int totalMatches = 0;

          if (snap.hasData) {
            for (var doc in snap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['isActive'] == true) {
                activeOffers++;
                availableCapital += (d['availableCapital'] ?? 0).toDouble();
              }
              totalMatches += ((d['matchedBorrowerIds'] as List?)?.length ?? 0);
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
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AVAILABLE CAPITAL',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snap.hasData ? AppFormatters.formatINR(availableCapital) : '...',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$activeOffers',
                          style: AppTextStyles.amountLarge.copyWith(color: Colors.white, fontSize: 24),
                        ),
                        Text('Active Offers', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalMatches',
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
                    label: 'Create New Offer',
                    onPressed: () => context.push('/create-offer'),
                    color: AppColors.emerald,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CardStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.tag
                .copyWith(color: color.withOpacity(0.7), letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h2.copyWith(color: color)),
      ],
    );
  }
}

class _LenderStatsRow extends ConsumerWidget {
  final String userId;
  const _LenderStatsRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox(height: 100);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colLenders)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        int activeOffers = 0;
        double availableCapital = 0;

        if (snap.hasData) {
          final docs = snap.data!.docs;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final isActive = data['isActive'] == true;
            final capital = (data['availableCapital'] ?? 0).toDouble();

            if (isActive) {
              activeOffers++;
              availableCapital += capital;
            }
          }
        }

        return SizedBox(
          height: 120,
          child: ListView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 12),
            children: [
              _StatCard2(
                  label: 'Available Capital',
                  value: snap.hasData
                      ? AppFormatters.formatINR(availableCapital)
                      : '...',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.gold),
              _StatCard2(
                  label: 'Active Offers',
                  value: snap.hasData ? '$activeOffers' : '...',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.emerald),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colMatches)
                    .where('lenderId', isEqualTo: userId)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.hasData ? snap.data!.docs.length : 0;
                  return _StatCard2(
                      label: 'Pending Requests',
                      value: count.toString(),
                      icon: Icons.inbox_rounded,
                      color: AppColors.info);
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colMatches)
                    .where('lenderId', isEqualTo: userId)
                    .where('status', isEqualTo: 'accepted')
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.hasData ? snap.data!.docs.length : 0;
                  return _StatCard2(
                      label: 'Accepted Deals',
                      value: count.toString(),
                      icon: Icons.handshake_rounded,
                      color: AppColors.success);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard2 extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard2(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: AppTextStyles.amountSmall
                    .copyWith(color: color, fontSize: 20, height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _ManageSection extends StatefulWidget {
  final String userId;
  const _ManageSection({required this.userId});

  @override
  State<_ManageSection> createState() => _ManageSectionState();
}

class _ManageSectionState extends State<_ManageSection> {
  static bool _browseBadge = false;

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
              color: Colors.black.withOpacity(0.05),
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
                icon: Icons.person_search_rounded,
                label: 'Browse',
                onTap: () async {
                  if (_browseBadge) setState(() => _browseBadge = false);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/borrower-search');
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
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (context.mounted) context.push('/auth/role-selection');
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
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2))),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2),
        ]),
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

class _IncomingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String id;
  const _IncomingCard({required this.data, required this.id});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        FirebaseFirestore.instance.collection(AppConstants.colRequests).doc(id).delete();
      },
      child: GestureDetector(
        onTap: () => context.push('/request/$id'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(
                AppFormatters.formatINR((data['loanAmount'] ?? 0).toDouble()),
                style: AppTextStyles.amountMedium,
              )),
              TagChip(label: data['collateralType'] ?? '', color: AppColors.info),
            ]),
            const SizedBox(height: 8),
            Text(data['description'] ?? '',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text(data['borrowerCity'] ?? '', style: AppTextStyles.caption),
              const SizedBox(width: 12),
              Icon(Icons.percent_rounded, color: AppColors.textMuted, size: 13),
              const SizedBox(width: 4),
              Text('Max ${data['maxInterestRatePerMonth'] ?? '-'}%/mo',
                  style: AppTextStyles.caption),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Respond',
                    style:
                        AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ),
            ]),
          ]),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
