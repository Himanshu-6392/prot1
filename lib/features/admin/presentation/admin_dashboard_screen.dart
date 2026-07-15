import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/admin_stats_provider.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../main.dart';
import 'admin_kyc_review_screen.dart';
import 'admin_platform_health_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ─── Background Blobs ───
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald.withOpacity(0.05),
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
                color: AppColors.gold.withOpacity(0.05),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),

          // ─── Main Content ───
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADMIN',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Command Center',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_outlined,
                              color: AppColors.textSecondary, size: 22),
                          onPressed: () => _showSettings(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Stats Strip ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ref.watch(adminStatsProvider).when(
                          data: (stats) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatPill(
                                    label: 'Users',
                                    value: '${stats.totalUsers}',
                                    color: AppColors.textPrimary),
                                _Divider(),
                                _StatPill(
                                    label: 'Lenders',
                                    value: '${stats.activeLenders}',
                                    color: AppColors.emerald),
                                _Divider(),
                                _StatPill(
                                    label: 'Requests',
                                    value: '${stats.openRequests}',
                                    color: AppColors.info),
                                _Divider(),
                                _StatPill(
                                    label: 'KYC',
                                    value: '${stats.kycPending}',
                                    color: AppColors.error),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          loading: () => const SizedBox(
                              height: 64,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                          error: (e, _) => const SizedBox.shrink(),
                        ),
                  ),
                ),

                // ── Section: Pending Actions ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Pending Actions'),
                ),
                SliverToBoxAdapter(
                  child: _PendingActionsSection(),
                ),

                // ── Section: Platform Health ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Platform Health'),
                ),
                SliverToBoxAdapter(
                  child: _PlatformHealthChart(),
                ),

                // ── Section: Recent Activity ─────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Recent Activity'),
                ),
                SliverToBoxAdapter(
                  child: _RecentActivityFeed(),
                ),

                // ── Section: Top Users ───────────────────────
                SliverToBoxAdapter(
                  child: _SectionLabel(label: 'Top Users'),
                ),
                SliverToBoxAdapter(
                  child: _TopUsersSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.palette_outlined, color: Colors.amber),
                ),
                title: Text('Toggle Theme',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                trailing: Icon(Icons.chevron_right,
                    color: AppColors.textPrimary.withOpacity(0.3)),
                onTap: () {
                  final current = ref.read(themeModeProvider);
                  ref.read(themeModeProvider.notifier).state =
                      current == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.logout_rounded, color: Colors.redAccent),
                ),
                title: Text('Sign Out',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                trailing: Icon(Icons.chevron_right,
                    color: AppColors.textPrimary.withOpacity(0.3)),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Section Label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.tag.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.8,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.border);
  }
}

// ─────────────────────────────────────────────
// Stats Strip Pill
// ─────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3
                .copyWith(color: color, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 1. Pending Actions Section (fully interactive)
// ─────────────────────────────────────────────
class _PendingActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const SizedBox(
                height: 60,
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }

          final docs = snap.data!.docs;

          final pendingKycDocs = docs
              .where((d) => (d.data() as Map)['kycStatus'] == 'pending')
              .toList();
          final blockedDocs = docs
              .where((d) => (d.data() as Map)['isBlocked'] == true)
              .toList();
          final unverifiedDocs = docs
              .where((d) =>
                  (d.data() as Map)['isVerified'] == false &&
                  (d.data() as Map)['kycStatus'] != 'pending')
              .toList();

          if (pendingKycDocs.isEmpty &&
              blockedDocs.isEmpty &&
              unverifiedDocs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.emerald.withOpacity(0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.emerald, size: 18),
                    const SizedBox(width: 10),
                    Text('All clear — no pending actions',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.emerald)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (pendingKycDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.badge_outlined,
                  label: 'KYC Reviews Pending',
                  count: pendingKycDocs.length,
                  color: AppColors.warning,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'KYC Pending',
                    docs: pendingKycDocs,
                    type: _PendingType.kyc,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
              if (blockedDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.block_rounded,
                  label: 'Blocked Accounts',
                  count: blockedDocs.length,
                  color: AppColors.error,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'Blocked Accounts',
                    docs: blockedDocs,
                    type: _PendingType.blocked,
                  ),
                ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.05),
              if (unverifiedDocs.isNotEmpty)
                _PendingTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Unverified Users',
                  count: unverifiedDocs.length,
                  color: AppColors.info,
                  onTap: () => _showPendingSheet(
                    context,
                    title: 'Unverified Users',
                    docs: unverifiedDocs,
                    type: _PendingType.unverified,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05),
            ],
          );
        },
      ),
    );
  }

  void _showPendingSheet(
    BuildContext context, {
    required String title,
    required List<QueryDocumentSnapshot> docs,
    required _PendingType type,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PendingUsersSheet(
          title: title, docs: docs, type: type),
    );
  }
}

// ─── Sheet showing users for a pending category ───
enum _PendingType { kyc, blocked, unverified }

class _PendingUsersSheet extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> docs;
  final _PendingType type;

  const _PendingUsersSheet(
      {required this.title, required this.docs, required this.type});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(title,
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${docs.length}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          // User list
          Flexible(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                      .copyWith(bottom: 32),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final uid = docs[i].id;
                return _PendingUserRow(
                    uid: uid, data: data, type: type);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single user row with inline action buttons ───
class _PendingUserRow extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;
  final _PendingType type;

  const _PendingUserRow(
      {required this.uid, required this.data, required this.type});

  @override
  State<_PendingUserRow> createState() => _PendingUserRowState();
}

class _PendingUserRowState extends State<_PendingUserRow> {
  bool _loading = false;

  Future<void> _act(Map<String, dynamic> updates,
      {String? successMsg}) async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(widget.uid)
          .update(updates);
      if (mounted && successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToKycReview(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminKycReviewScreen(
        uid: widget.uid,
        userData: widget.data,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Unknown';
    final email = widget.data['email'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isKyc = widget.type == _PendingType.kyc;

    return GestureDetector(
      onTap: isKyc ? () => _navigateToKycReview(context) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(initial,
                        style: AppTextStyles.labelMedium
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(email,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (_loading)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else if (isKyc)
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons (differ by type; KYC goes to detail screen)
            if (!_loading && !isKyc) ..._buildActions(),
            // For KYC: show a subtle hint
            if (isKyc)
              Text(
                'Tap to review documents',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    switch (widget.type) {
      case _PendingType.kyc:
        return [
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Approve KYC',
                color: AppColors.emerald,
                onTap: () => _act({
                  'kycStatus': 'verified',
                  'isVerified': true,
                }, successMsg: 'KYC approved for ${widget.data['name']}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Reject KYC',
                color: AppColors.error,
                outlined: true,
                onTap: () => _act({
                  'kycStatus': 'rejected',
                  'isVerified': false,
                }, successMsg: 'KYC rejected for ${widget.data['name']}'),
              ),
            ),
          ]),
        ];
      case _PendingType.blocked:
        return [
          _ActionBtn(
            label: 'Unblock User',
            color: AppColors.emerald,
            onTap: () => _act({
              'isBlocked': false,
            }, successMsg: '${widget.data['name']} has been unblocked'),
          ),
        ];
      case _PendingType.unverified:
        return [
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Verify',
                color: AppColors.info,
                onTap: () => _act({
                  'kycStatus': 'verified',
                  'isVerified': true,
                }, successMsg: '${widget.data['name']} verified'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Block',
                color: AppColors.error,
                outlined: true,
                onTap: () => _act({
                  'isBlocked': true,
                }, successMsg: '${widget.data['name']} blocked'),
              ),
            ),
          ]),
        ];
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined ? color.withOpacity(0.5) : color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _PendingTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. Platform Health Chart (7-day signups bar)
// ─────────────────────────────────────────────
class _PlatformHealthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPlatformHealthChart();
  }
}

// ─────────────────────────────────────────────
// 3. Recent Activity Feed
// ─────────────────────────────────────────────
class _RecentActivityFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colRequests)
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, reqSnap) {
              // Merge and sort both streams
              final List<_ActivityItem> items = [];

              if (userSnap.hasData) {
                for (var doc in userSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'];
                  DateTime? time;
                  if (ts is Timestamp) time = ts.toDate();
                  items.add(_ActivityItem(
                    icon: Icons.person_add_outlined,
                    title: '${data['name'] ?? 'Someone'} joined',
                    subtitle: data['role'] ?? 'user',
                    time: time,
                    color: AppColors.info,
                  ));
                }
              }

              if (reqSnap.hasData) {
                for (var doc in reqSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['createdAt'];
                  DateTime? time;
                  if (ts is Timestamp) time = ts.toDate();
                  final amount = (data['loanAmount'] ?? 0).toDouble();
                  items.add(_ActivityItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Loan request posted',
                    subtitle: AppFormatters.formatINRCompact(amount),
                    time: time,
                    color: AppColors.emerald,
                  ));
                }
              }

              // Sort newest first
              items.sort((a, b) {
                if (a.time == null && b.time == null) return 0;
                if (a.time == null) return 1;
                if (b.time == null) return -1;
                return b.time!.compareTo(a.time!);
              });

              final display = items.take(6).toList();

              if (display.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No recent activity',
                      style: AppTextStyles.caption),
                );
              }

              return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                child: Column(
                  children: List.generate(display.length, (i) {
                    final item = display[i];
                    final isLast = i == display.length - 1;
                    return _ActivityTile(
                        item: item, isLast: isLast, index: i);
                  }),
                ),
              ).animate().fadeIn(duration: 500.ms);
            },
          );
        },
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? time;
  final Color color;
  _ActivityItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.time,
      required this.color});
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;
  final int index;
  const _ActivityTile(
      {required this.item, required this.isLast, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary, fontSize: 12)),
                const SizedBox(height: 1),
                Text(item.subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            item.time != null
                ? AppFormatters.formatRelative(item.time!)
                : '—',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index));
  }
}

// ─────────────────────────────────────────────
// 4. Top Lenders / Top Borrowers
// ─────────────────────────────────────────────
class _TopUsersSection extends StatefulWidget {
  @override
  State<_TopUsersSection> createState() => _TopUsersSectionState();
}

class _TopUsersSectionState extends State<_TopUsersSection>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle tabs
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tab,
              labelPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              dividerColor: Colors.transparent,
              labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Top Lenders'),
                Tab(text: 'Top Borrowers'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tab content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _tab.index == 0
                ? _TopRoleList(role: 'lender', key: const ValueKey('lenders'))
                : _TopRoleList(
                    role: 'borrower', key: const ValueKey('borrowers')),
          ),
        ],
      ),
    );
  }
}

class _TopRoleList extends StatelessWidget {
  final String role;
  const _TopRoleList({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .where('role', isEqualTo: role)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 60,
              child:
                  Center(child: CircularProgressIndicator(strokeWidth: 2)));
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No ${role}s yet',
                  style: AppTextStyles.caption),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: List.generate(docs.length, (i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final initial =
                  name.isNotEmpty ? name[0].toUpperCase() : '?';
              final kycStatus = data['kycStatus'] ?? '';
              final isVerified = data['isVerified'] == true;
              final isLast = i == docs.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                              color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                            color: i == 0
                                ? AppColors.emerald
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(initial,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 1),
                          Text(
                            data['email'] ?? '',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Verified',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      )
                    else if (kycStatus == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Pending',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('New',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 9)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * i));
            }),
          ),
        );
      },
    );
  }
}


