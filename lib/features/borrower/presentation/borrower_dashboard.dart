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
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── App Bar ───────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, user)),

            // ─── Stats Row ─────────────────────
            SliverToBoxAdapter(child: _StatsRow(userId: uid)),

            // ─── Quick Actions ─────────────────
            SliverToBoxAdapter(child: _QuickActions()),

            // ─── My Requests ───────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'My Requests',
                isExpandable: true,
                isExpanded: _requestsExpanded,
                onToggle: () => setState(() => _requestsExpanded = !_requestsExpanded),
              ),
            ),
            if (_requestsExpanded) _MyRequestsSliver(userId: uid),

            // ─── Nearby Lenders (For Borrowers or Both) ───
            if (user?.role != UserRole.lender) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Lenders Near You', onSeeAll: () => context.go('/search')),
              ),
              SliverToBoxAdapter(child: _NearbyLendersRow()),
            ],

            // ─── Borrowers Near You (For Lenders or Both) ───
            if (user?.role != UserRole.borrower) ...[
              SliverToBoxAdapter(
                child: SectionHeader(title: 'Borrowers Near You', onSeeAll: () {}),
              ),
              SliverToBoxAdapter(child: _BorrowersNearYouRow()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))
                    .animate().fadeIn(),
                Text(user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'User',
                    style: AppTextStyles.h1).animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
          // Theme Toggle
          IconButton(
            onPressed: () => AppColors.toggleTheme(context),
            icon: Icon(
              AppColors.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(width: 12),
          // Avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient:     AppColors.goldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  (user?.name != null && user!.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                  style: AppTextStyles.h3.copyWith(color: AppColors.textInverse),
                ),
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        ],
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
            } else if (status == 'open' || status == 'matched' || status == 'accepted') {
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
                value: snap.hasData ? AppFormatters.formatINR(totalRequested) : '...', 
                icon: Icons.account_balance_wallet_rounded, 
                color: AppColors.gold
              ),
              _StatCard(
                label: 'Active Requests', 
                value: snap.hasData ? '$activeLoans' : '...', 
                icon: Icons.bolt_rounded, 
                color: AppColors.goldLight
              ),
              _StatCard(
                label: 'Completed Deals', 
                value: snap.hasData ? '$completedDeals' : '...', 
                icon: Icons.check_circle_rounded, 
                color: AppColors.emerald
              ),
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
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                          style: AppTextStyles.h1.copyWith(fontSize: 32, height: 1),
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
                            Icon(Icons.lock_rounded, size: 20, color: AppColors.textPrimary.withOpacity(0.4)),
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
            content: Text('You must complete KYC verification before posting a loan request.', style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel', style: AppTextStyles.bodyMedium)),
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                  context.push('/profile/kyc');
                },
                child: Text('Verify Now', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        context.push('/post-request');
      }
    }

    final actions = [
      _Action('Find Lenders', Icons.search_rounded, AppColors.gold, () => context.go('/search')),
      _Action('Post Request', Icons.add_circle_rounded, AppColors.emerald, handlePostRequest),
      _Action('Saved', Icons.bookmark_rounded, AppColors.info, () => context.push('/saved-lenders')),
      _Action('Chat', Icons.chat_bubble_rounded, AppColors.success, () => context.push('/chat')),
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
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _Action(this.label, this.icon, this.color, this.onTap);
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
              width: 56, height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    action.color.withOpacity(0.12),
                    action.color.withOpacity(0.02),
                  ],
                ),
                border: Border.all(
                  color: action.color.withOpacity(0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Icon(action.icon, color: action.color, size: 26),
              ),
            ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 500.ms),
            const SizedBox(height: 8),
            Text(action.label, 
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
Future<void> _seedDemoRequests(String userId) async {
  final firestore = FirebaseFirestore.instance;
  final now = Timestamp.now();

  final demos = [
    {
      'borrowerId': userId,
      'borrowerName': 'Test User',
      'borrowerCity': 'Mumbai',
      'loanAmount': 150000.0,
      'collateralType': 'Gold',
      'collateralValue': 200000.0,
      'maxInterestRatePerMonth': 1.5,
      'tenureMonths': 12,
      'description': 'Need funds for home renovation. Have gold jewellery as collateral.',
      'isVerified': true,
      'status': 'open',
      'collateralPhotoUrls': [],
      'savedByLenderIds': [],
      'borrowerRating': 4.5,
      'createdAt': now,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    },
    {
      'borrowerId': userId,
      'borrowerName': 'Test User',
      'borrowerCity': 'Delhi',
      'loanAmount': 75000.0,
      'collateralType': 'Electronics',
      'collateralValue': 90000.0,
      'maxInterestRatePerMonth': 2.0,
      'tenureMonths': 6,
      'description': 'Medical emergency. MacBook Pro 2023 as collateral.',
      'isVerified': false,
      'status': 'matched',
      'collateralPhotoUrls': [],
      'savedByLenderIds': [],
      'borrowerRating': null,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 25))),
    },
    {
      'borrowerId': userId,
      'borrowerName': 'Test User',
      'borrowerCity': 'Bangalore',
      'loanAmount': 300000.0,
      'collateralType': 'Property',
      'collateralValue': 1500000.0,
      'maxInterestRatePerMonth': 1.2,
      'tenureMonths': 24,
      'description': 'Business expansion loan. Clear property title available.',
      'isVerified': true,
      'status': 'accepted',
      'collateralPhotoUrls': [],
      'savedByLenderIds': [],
      'borrowerRating': 4.8,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 20))),
    },
  ];

  final batch = firestore.batch();
  for (final data in demos) {
    final doc = firestore.collection(AppConstants.colRequests).doc();
    batch.set(doc, data);
  }
  await batch.commit();
}

class _MyRequestsSliver extends ConsumerWidget {
  final String userId;
  const _MyRequestsSliver({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  EmptyState(
                    icon:     Icons.description_outlined,
                    title:    'No requests yet',
                    subtitle: 'Post your first loan request and connect with lenders.',
                    action:   AppButton(label: 'Post a Request', onPressed: () => context.push('/post-request'), width: 200),
                  ),
                  const SizedBox(height: 12),
                  // Demo seed button for testing
                  OutlinedButton.icon(
                    onPressed: () => _seedDemoRequests(userId),
                    icon: const Icon(Icons.science_outlined, size: 16),
                    label: const Text('Load Demo Data'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: docs.map((d) {
              final req = LoanRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id);
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
    LoanRequestStatus.open      => AppColors.gold,
    LoanRequestStatus.matched   => AppColors.info,
    LoanRequestStatus.accepted  => AppColors.emerald,
    LoanRequestStatus.completed => AppColors.success,
    LoanRequestStatus.cancelled => AppColors.error,
    LoanRequestStatus.expired   => AppColors.textMuted,
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
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppFormatters.formatINR(req.loanAmount),
                                style: AppTextStyles.amountMedium.copyWith(fontSize: 17),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${AppFormatters.formatTenure(req.tenureMonths)} · ${req.maxInterestRatePerMonth}%/mo',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TagChip(label: req.status.name.toUpperCase(), color: statusColor),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(Icons.expand_more_rounded, color: AppColors.textMuted, size: 24),
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
                      Divider(height: 1, thickness: 1, color: AppColors.border.withOpacity(0.5)),
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
                                TagChip(label: req.collateralType, color: AppColors.info),
                                TagChip(label: AppFormatters.formatTenure(req.tenureMonths), color: AppColors.textSecondary),
                                TagChip(label: '${req.maxInterestRatePerMonth}%/mo', color: AppColors.warning),
                                if (req.isVerified)
                                  TagChip(label: '✓ Verified', color: AppColors.emerald),
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
                                Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 13),
                                const SizedBox(width: 3),
                                Flexible(child: Text(req.borrowerCity, style: AppTextStyles.caption)),
                                const SizedBox(width: 10),
                                Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted, size: 13),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Collateral: ${AppFormatters.formatINR(req.collateralValue)}',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const Spacer(),
                                Text(AppFormatters.formatRelative(req.createdAt), style: AppTextStyles.caption),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // View details button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/request/${req.id}'),
                                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                label: const Text('View Full Details'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: statusColor,
                                  side: BorderSide(color: statusColor.withOpacity(0.4)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
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
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (_, __) => ShimmerBox(width: 160, height: 160, borderRadius: 16),
            ),
          );
        }
        var docs = snap.data!.docs.toList();
        docs.sort((a, b) {
          final aFeat = (a.data() as Map<String, dynamic>)['isFeatured'] == true ? 1 : 0;
          final bFeat = (b.data() as Map<String, dynamic>)['isFeatured'] == true ? 1 : 0;
          return bFeat.compareTo(aFeat);
        });
        if (docs.length > 6) docs = docs.sublist(0, 6);
        
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
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient:     AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(
                            (data['businessName'] ?? 'L')[0].toUpperCase(),
                            style: AppTextStyles.h4.copyWith(color: Colors.white),
                          )),
                        ),
                        Spacer(),
                        if (data['isVerified'] == true)
                          Icon(Icons.verified_rounded, color: AppColors.emerald, size: 16),
                      ]),
                      SizedBox(height: 10),
                      Text(data['businessName'] ?? '', style: AppTextStyles.labelLarge,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2),
                      Text(data['city'] ?? '', style: AppTextStyles.caption),
                      Spacer(),
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

// ──────────────────────────────────────────────
class _BorrowersNearYouRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'borrower')
          .limit(6)
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
              itemBuilder: (_, __) => ShimmerBox(width: 160, height: 160, borderRadius: 16),
            ),
          );
        }
        
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Text('No borrowers near you.', style: TextStyle(color: Colors.grey)),
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
              final name = data['name'] ?? 'Borrower';
              final city = data['city'] ?? 'Unknown City';
              final rating = data['rating']?.toString() ?? 'New';
              
              return NeumorphicContainer(
                width: 160,
                padding: const EdgeInsets.all(14),
                borderRadius: 24,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.info.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'B',
                        style: AppTextStyles.h2.copyWith(color: AppColors.info),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 12),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            city,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
                          const SizedBox(width: 4),
                          Text(rating, style: AppTextStyles.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

