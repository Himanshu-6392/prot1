import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/notification_model.dart';

// ─── Timeline-grouped notifications screen ───────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _orbController;

  // 'all' means no type filter applied
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFilter = filter);
  }

  /// Groups notifications into Today / Yesterday / Earlier
  Map<String, List<NotificationModel>> _group(
      List<NotificationModel> notifs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationModel>> result = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final n in notifs) {
      final d = DateTime(
          n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d == today) {
        result['Today']!.add(n);
      } else if (d == yesterday) {
        result['Yesterday']!.add(n);
      } else {
        result['Earlier']!.add(n);
      }
    }

    result.removeWhere((_, v) => v.isEmpty);
    return result;
  }

  Future<void> _markAllRead(String uid) async {
    HapticFeedback.lightImpact();
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: user == null
          ? _buildLoading()
          : StreamBuilder<QuerySnapshot>(
              // ── Real Firestore query — filtered by type when active ──
              stream: _buildStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }

                // Apply client-side type filter
                final docs = snapshot.data?.docs ?? [];
                final allNotifs = docs
                    .map((d) => NotificationModel.fromMap(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList();

                final notifs = _selectedFilter == 'all'
                    ? allNotifs
                    : allNotifs
                        .where((n) => n.type == _selectedFilter)
                        .toList();

                final grouped = _group(notifs);
                final unreadCount =
                    allNotifs.where((n) => !n.isRead).length;

                return _buildBody(
                  context: context,
                  grouped: grouped,
                  unreadCount: unreadCount,
                  totalCount: allNotifs.length,
                  uid: user.uid,
                  isEmpty: notifs.isEmpty,
                );
              },
            ),
    );
  }

  /// Always fetches all notifications ordered by date.
  /// Client-side filtering is applied in the builder for instant response
  /// without needing Firestore composite indexes.
  Stream<QuerySnapshot> _buildStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _buildBody({
    required BuildContext context,
    required Map<String, List<NotificationModel>> grouped,
    required int unreadCount,
    required int totalCount,
    required String uid,
    required bool isEmpty,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Collapsing header ───────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _NotifHeaderDelegate(
            pulseController: _pulseController,
            unreadCount: unreadCount,
            totalCount: totalCount,
            topPadding: MediaQuery.of(context).padding.top,
            onMarkAll: unreadCount > 0 ? () => _markAllRead(uid) : null,
          ),
        ),

        // ── Filter bar — pinned below header ────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterBarDelegate(
            selected: _selectedFilter,
            onChanged: _onFilterChanged,
          ),
        ),

        if (isEmpty) ...[
          SliverFillRemaining(
            child: _EmptyState(
              orbController: _orbController,
              filter: _selectedFilter,
            ),
          ),
        ] else ...[
          // ── Grouped sections ──────────────────────────────────────────
          for (final entry in grouped.entries) ...[
            _SectionHeader(label: entry.key),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final notif = entry.value[i];
                    final isLast = i == entry.value.length - 1;
                    return _NotifRow(
                      notif: notif,
                      isLast: isLast,
                      animIndex: i,
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 130,
            child: Container(color: AppColors.surface),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _SkeletonRow(i),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Couldn\'t load notifications', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(msg,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// --- Sliver Header Delegate ---

class _NotifHeaderDelegate extends SliverPersistentHeaderDelegate {
  final AnimationController pulseController;
  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAll;
  final double topPadding;

  // Visible content height (below status bar)
  static const double _contentExpanded = 90.0;
  static const double _contentCollapsed = 52.0;

  double get kExpanded => topPadding + _contentExpanded;
  double get kCollapsed => topPadding + _contentCollapsed;

  const _NotifHeaderDelegate({
    required this.pulseController,
    required this.unreadCount,
    required this.totalCount,
    required this.onMarkAll,
    required this.topPadding,
  });

  @override
  double get minExtent => kCollapsed;
  @override
  double get maxExtent => kExpanded;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (kExpanded - kCollapsed)).clamp(0.0, 1.0);
    final titleSize = 26.0 - (t * 8.0); // 26→18
    final isExpanded = t < 0.5;

    return ClipRect(
      child: Container(
        color: AppColors.surface,
        child: Stack(
          children: [
            // ── Content row ───────────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              top: topPadding + 10,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title + label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpanded)
                          Opacity(
                            opacity: (1.0 - t * 2.0).clamp(0.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                'ACTIVITY',
                                style: AppTextStyles.tag.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 2.0,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          'Notifications',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right side ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing unread badge
                      if (unreadCount > 0)
                        AnimatedBuilder(
                          animation: pulseController,
                          builder: (_, __) {
                            final pulse = 1.0 +
                                math.sin(
                                        pulseController.value * math.pi * 2) *
                                    0.10;
                            return Transform.scale(
                              scale: pulse,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (unreadCount > 0 && onMarkAll != null)
                        const SizedBox(width: 10),

                      // Minimal mark-read action
                      if (onMarkAll != null)
                        GestureDetector(
                          onTap: onMarkAll,
                          child: Text(
                            'Mark read',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom accent line ─────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  Container(height: 1, color: AppColors.border),
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (_, __) {
                      final w = unreadCount > 0
                          ? (55.0 + pulseController.value * 18.0)
                          : 36.0;
                      return Container(
                        height: 2,
                        width: w,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_NotifHeaderDelegate old) =>
      old.unreadCount != unreadCount ||
      old.totalCount != totalCount ||
      old.topPadding != topPadding;
}


// ─── Filter Bar Delegate ─────────────────────────────────────────────────────

const List<Map<String, String>> _kFilters = [
  {'key': 'all',     'label': 'All'},
  {'key': 'match',   'label': 'Match'},
  {'key': 'message', 'label': 'Messages'},
  {'key': 'kyc',     'label': 'KYC'},
  {'key': 'review',  'label': 'Review'},
  {'key': 'system',  'label': 'System'},
];

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBarDelegate({
    required this.selected,
    required this.onChanged,
  });

  static const double kH = 52;

  @override
  double get minExtent => kH;
  @override
  double get maxExtent => kH;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      height: kH,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: _kFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _kFilters[i];
                final isActive = f['key'] == selected;
                return GestureDetector(
                  onTap: () => onChanged(f['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.emerald
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.emerald
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      f['label']!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate old) => old.selected != selected;
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: AppTextStyles.tag.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Row (timeline style) ───────────────────────────────────────

class _NotifRow extends StatefulWidget {
  final NotificationModel notif;
  final bool isLast;
  final int animIndex;

  const _NotifRow({
    required this.notif,
    required this.isLast,
    required this.animIndex,
  });

  @override
  State<_NotifRow> createState() => _NotifRowState();
}

class _NotifRowState extends State<_NotifRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notif;
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline column ──────────────────────────────────────
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Icon circle
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: notif.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: isUnread
                          ? Border.all(
                              color: notif.color.withOpacity(0.5),
                              width: 1.5)
                          : null,
                    ),
                    child: Icon(notif.icon,
                        color: notif.color,
                        size: isUnread ? 18 : 17),
                  ),
                  // Connector line
                  if (!widget.isLast)
                    Container(
                      width: 1.5,
                      height: 32,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.border,
                            AppColors.border.withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 6, right: 4),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: isUnread
                      ? notif.color.withOpacity(0.04)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnread
                        ? notif.color.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + dot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: notif.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Row(
                      children: [
                        _TypePill(type: notif.type, color: notif.color),
                        const Spacer(),
                        Text(
                          AppFormatters.formatRelative(notif.createdAt),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            .animate(delay: Duration(milliseconds: widget.animIndex * 60))
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.05, end: 0),
      ),
    );
  }
}

// ─── Type Pill ────────────────────────────────────────────────────────────────

class _TypePill extends StatelessWidget {
  final String type;
  final Color color;
  const _TypePill({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.tag
            .copyWith(color: color, fontSize: 9, letterSpacing: 0.8),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AnimationController orbController;
  final String filter;
  const _EmptyState({
    required this.orbController,
    this.filter = 'all',
  });

  String get _emptyMessage {
    if (filter == 'all') return 'New activity will appear here.';
    final label = _kFilters
        .firstWhere((f) => f['key'] == filter,
            orElse: () => {'label': filter})
        ['label']!;
    return 'No $label notifications yet.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stacked circles with orb animation
          AnimatedBuilder(
            animation: orbController,
            builder: (_, __) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Transform.scale(
                      scale: 1.0 + orbController.value * 0.06,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Middle ring
                    Transform.scale(
                      scale: 1.0 - orbController.value * 0.04,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceAlt,
                        ),
                      ),
                    ),
                    // Icon
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    // Small orbiting dot
                    Transform.rotate(
                      angle: orbController.value * math.pi * 2,
                      child: Transform.translate(
                        offset: const Offset(55, 0),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Small second orbiting dot (offset)
                    Transform.rotate(
                      angle: orbController.value * math.pi * 2 + math.pi,
                      child: Transform.translate(
                        offset: const Offset(55, 0),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            filter == 'all' ? 'You\'re all caught up' : 'Nothing here',
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            _emptyMessage,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 48),
          // Divider with icon
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.notifications_none_rounded,
                    size: 16, color: AppColors.textMuted),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

// ─── Skeleton Row ─────────────────────────────────────────────────────────────

class _SkeletonRow extends StatelessWidget {
  final int index;
  const _SkeletonRow(this.index);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 4, top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 1000.ms,
          delay: Duration(milliseconds: index * 100),
          color: Colors.white.withOpacity(0.7),
        );
  }
}
