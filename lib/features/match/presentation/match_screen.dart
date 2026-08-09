import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isLender = user.role == UserRole.lender;

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bg, AppColors.bg.withOpacity(0.9), AppColors.bg.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(isLender ? 'My Offers' : 'Match Requests',
              style: AppTextStyles.h2),
        ),
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colMatches)
                .where(isLender ? 'lenderId' : 'borrowerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading matches: ${snap.error}', style: TextStyle(color: Colors.red)),
                  )
                );
              }
              if (!snap.hasData)
                return Center(
                    child: CircularProgressIndicator(color: AppColors.gold));
              
              var docs = snap.data!.docs.toList();

              // Filter out self-matches (lenderId == borrowerId) — prevents own
              // requests from appearing in the list when the user plays both roles.
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final lId = data['lenderId'] as String? ?? '';
                final bId = data['borrowerId'] as String? ?? '';
                return lId != bId && lId.isNotEmpty && bId.isNotEmpty;
              }).toList();

              // Filter out declined matches — keep the list clean.
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['status'] as String?) != MatchStatus.declined.name;
              }).toList();

              // Sort locally to avoid needing a composite index in Firestore
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty)
                return EmptyState(
                  icon: isLender
                      ? Icons.receipt_long_rounded
                      : Icons.handshake_outlined,
                  title: isLender ? 'No active offers' : 'No matches yet',
                  subtitle: isLender
                      ? 'Your outgoing loan offers will appear here.'
                      : 'When lenders respond to your requests, they\'ll appear here.',
                );

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final match = MatchModel.fromMap(
                      docs[i].data() as Map<String, dynamic>, docs[i].id);
                  return _MatchCard(match: match, isLender: isLender)
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends ConsumerStatefulWidget {
  final MatchModel match;
  final bool isLender;
  const _MatchCard({required this.match, required this.isLender});

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  late final Future<Map<String, String>> _detailsFuture;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _fetchDetails();
  }

  Future<Map<String, String>> _fetchDetails() async {
    String name = 'Unknown';
    String req = 'Direct Request';

    try {
      if (widget.isLender) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.match.borrowerId)
            .get();
        if (doc.exists) name = doc.data()?['name'] ?? 'Borrower';
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('lenders')
            .doc(widget.match.lenderId)
            .get();
        if (doc.exists && doc.data()?['businessName'] != null) {
          name = doc.data()!['businessName'];
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.match.lenderId)
              .get();
          if (userDoc.exists) name = userDoc.data()?['name'] ?? 'Lender';
        }
      }

      if (widget.match.requestId.isNotEmpty) {
        final reqDoc = await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.match.requestId)
            .get();
        if (reqDoc.exists) {
          final amt = reqDoc.data()?['loanAmount'] ?? 0;
          final type = reqDoc.data()?['collateralType'] ?? 'Unknown';
          req = 'Loan: ${AppFormatters.formatINR(amt.toDouble())} ($type)';
        }
      }
    } catch (e) {
      // Ignore
    }

    return {'name': name, 'request': req};
  }

  Future<bool> _accept() async {
    HapticFeedback.mediumImpact();
    final chatRoomId = '${widget.match.id}_chat';
    await FirebaseFirestore.instance
        .collection(AppConstants.colMatches)
        .doc(widget.match.id)
        .update({
      'status': MatchStatus.accepted.name,
      'chatRoomId': chatRoomId,
      'updatedAt': DateTime.now(),
    });

    bool isBorrowerInitiated = widget.match.offeredAmount == null;

    if (isBorrowerInitiated) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.match.borrowerId)
          .collection('notifications')
          .add({
        'title': 'Request Accepted! 🎉',
        'body': 'A lender accepted your direct request! Start chatting to finalize the deal.',
        'type': 'match',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.match.lenderId)
          .collection('notifications')
          .add({
        'title': 'Offer Accepted! 🎉',
        'body': 'Your offer of ₹${widget.match.offeredAmount} was accepted! Start chatting to finalize the deal.',
        'type': 'match',
        'isRead': false,
        'createdAt': DateTime.now(),
      });
    }

    if (mounted) context.push('/chat/$chatRoomId');
    return true;
  }

  Future<bool> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Decline Request?', style: AppTextStyles.h3),
        content: Text(
          'Are you sure you want to decline this match? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Decline', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    if (!mounted) return false;
    await FirebaseFirestore.instance
        .collection(AppConstants.colMatches)
        .doc(widget.match.id)
        .update({
      'status': MatchStatus.declined.name,
      'updatedAt': DateTime.now(),
    });
    return true;
  }

  IconData _statusIcon(MatchStatus s) => switch (s) {
        MatchStatus.pending => Icons.schedule_rounded,
        MatchStatus.accepted => Icons.check_circle_rounded,
        MatchStatus.declined => Icons.cancel_rounded,
        MatchStatus.completed => Icons.verified_rounded,
      };

  Color _statusColor(MatchStatus s) => switch (s) {
        MatchStatus.pending => AppColors.gold,
        MatchStatus.accepted => AppColors.emerald,
        MatchStatus.declined => AppColors.error,
        MatchStatus.completed => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.match.status);
    final isPending = widget.match.status == MatchStatus.pending;
    final isActionable = isPending && ((widget.match.offeredAmount == null && widget.isLender) || (widget.match.offeredAmount != null && !widget.isLender));

    // 5. Swipe-to-Action (Tinder-style) wrapper logic is at the bottom
    Widget cardContent = GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded), // 4. Fluid Expansion Trigger
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface, // Clean white card
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isPending
                  ? AppColors.gold.withOpacity(0.5)
                  : AppColors.border.withOpacity(0.6),
              width: isPending ? 1.5 : 1),
          // Static shadow here, dynamic Pulse shadow applied externally later
          boxShadow: [
            BoxShadow(
              color: AppColors.borderGlow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FutureBuilder<Map<String, String>>(
          future: _detailsFuture,
          builder: (context, snapshot) {
            final details = snapshot.data ?? {'name': 'Loading...', 'request': '...'};
            final name = details['name']!;
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(widget.match.status), size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(widget.match.status.name.toUpperCase(),
                          style: AppTextStyles.tag.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(AppFormatters.formatRelative(widget.match.createdAt),
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 2. "Trust Score" Avatar Rings
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFF34D399)],
                      ),
                      boxShadow: [BoxShadow(color: AppColors.emerald.withOpacity(0.4), blurRadius: 8)],
                    ),
                    padding: const EdgeInsets.all(3), // Border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface, // Inner gap color
                      ),
                      padding: const EdgeInsets.all(2), // Inner gap thickness
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceAlt,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: AppTextStyles.h2.copyWith(
                              color: widget.isLender ? AppColors.emeraldDark : AppColors.gold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white54),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            widget.isLender
                                ? 'Borrower: $name'
                                : 'Lender: $name',
                            style: AppTextStyles.h3.copyWith(fontSize: 16, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(details['request']!, 
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  
                  // Chevron indicating fluid expansion
                  Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                ],
              ),
              
              // 4. Fluid Expansion Details
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                child: !_isExpanded ? const SizedBox() : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.match.offeredAmount != null && widget.match.offeredInterestRate != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_offer_rounded, size: 16, color: AppColors.gold),
                                const SizedBox(width: 6),
                                Text(widget.isLender ? 'Your Offer' : 'Lender\'s Offer',
                                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Amount', style: AppTextStyles.caption),
                                    const SizedBox(height: 2),
                                    Text(
                                        AppFormatters.formatINR(widget.match.offeredAmount!),
                                        style: AppTextStyles.labelLarge.copyWith(fontSize: 16)),
                                  ],
                                ),
                                Container(width: 1, height: 30, color: AppColors.border),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Interest Rate', style: AppTextStyles.caption),
                                    const SizedBox(height: 2),
                                    Text('${widget.match.offeredInterestRate}%/mo',
                                        style: AppTextStyles.labelLarge.copyWith(fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                            if (widget.match.offerMessage != null && widget.match.offerMessage!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.format_quote_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('"${widget.match.offerMessage}"',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (isActionable) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: AppButton(
                                label: 'Accept Offer',
                                onPressed: _accept,
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                color: AppColors.emerald)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: AppButton(
                                label: 'Decline',
                                onPressed: () => _decline(),
                                isOutlined: true,
                                color: AppColors.error)),
                      ]),
                      const SizedBox(height: 12),
                      Center(child: Text('Tip: Swipe card to quickly Accept or Decline', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted))),
                    ],
                    if (widget.match.status == MatchStatus.accepted) ...[
                      const SizedBox(height: 20),
                      // 3. Shimmering "Open Chat" Button
                      AppButton(
                        label: 'Open Chat',
                        onPressed: () => context.push('/chat/${widget.match.chatRoomId}'),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                        color: AppColors.gold,
                      ).animate(onPlay: (c) => c.repeat(reverse: false)).shimmer(duration: 2.seconds, color: Colors.white24, delay: 1.seconds),
                    ],
                  ],
                ),
              ),
            ]);
          }
        ),
      ),
    );

    // 1. The "Pulse" Match Card (Glow animation applied conditionally based on status)
    if (widget.match.status == MatchStatus.accepted) {
      cardContent = cardContent.animate(onPlay: (c) => c.repeat(reverse: true)).boxShadow(
        begin: BoxShadow(color: AppColors.emerald.withOpacity(0.0), blurRadius: 0, spreadRadius: 0),
        end: BoxShadow(color: AppColors.emerald.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
        duration: 1500.ms,
      );
    } else if (isActionable) {
      cardContent = cardContent.animate(onPlay: (c) => c.repeat(reverse: true)).boxShadow(
        begin: BoxShadow(color: AppColors.gold.withOpacity(0.0), blurRadius: 0, spreadRadius: 0),
        end: BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
        duration: 1500.ms,
      );
    }

    // 5. Swipe-to-Action Implementation
    if (isActionable) {
      return Dismissible(
        key: Key(widget.match.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) { // Swipe Left -> Decline
            return await _decline();
          } else if (direction == DismissDirection.startToEnd) { // Swipe Right -> Accept
            return await _accept();
          }
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(24)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(24)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 32),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

// ─────────────────────────────────────────────────────
// Request Detail Screen
// ─────────────────────────────────────────────────────
class RequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Loan Request Detail', style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colRequests)
            .doc(requestId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          if (!snap.data!.exists)
            return Center(
                child: Text('Request not found', style: AppTextStyles.h3));
          final data = snap.data!.data() as Map<String, dynamic>;

          final user = ref.watch(currentUserProvider).valueOrNull;
          final isOwner = user?.uid == data['borrowerId'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HERO CARD (Amount & Stats) ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppFormatters.formatINR((data['loanAmount'] ?? 0).toDouble()),
                        style: AppTextStyles.amountLarge.copyWith(fontSize: 40),
                      ),
                      const SizedBox(height: 4),
                      Text('Requested Loan Amount', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      Divider(color: AppColors.border),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _DetailStat('Collateral', data['collateralType'] ?? '—'),
                          Container(width: 1, height: 32, color: AppColors.border),
                          _DetailStat('Max Rate', '${data['maxInterestRatePerMonth'] ?? '-'}%/mo'),
                          Container(width: 1, height: 32, color: AppColors.border),
                          _DetailStat('Tenure', AppFormatters.formatTenure(data['tenureMonths'] ?? 1)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),
                Text('Borrower Details', style: AppTextStyles.h3),
                const SizedBox(height: 12),

                // ─── BORROWER CARD ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (data['borrowerName']?.toString().isNotEmpty == true)
                                ? data['borrowerName'].toString()[0].toUpperCase()
                                : 'B',
                            style: AppTextStyles.h2.copyWith(color: AppColors.gold, fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(data['borrowerName'] ?? 'Unknown', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                                if (data['isVerified'] == true) ...[
                                  const SizedBox(width: 6),
                                  VerifiedBadge(),
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(data['borrowerCity'] ?? 'Location not specified', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),
                Text('Loan Description', style: AppTextStyles.h3),
                const SizedBox(height: 12),

                // ─── DESCRIPTION CARD ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    data['description']?.isEmpty == true ? 'No description provided.' : data['description'] ?? 'No description provided.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),
                Text('Collateral Overview', style: AppTextStyles.h3),
                const SizedBox(height: 12),

                // ─── COLLATERAL CARD ───
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow2('Collateral Type', data['collateralType'] ?? '—'),
                      const Divider(height: 24),
                      _DetailRow2('Estimated Value', AppFormatters.formatINR((data['collateralValue'] ?? 0).toDouble())),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                if (!isOwner) ...[
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Send Offer to Borrower',
                    onPressed: () {
                      if (user == null) return;
                      _showMakeOfferSheet(context, user.uid, data, requestId);
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                ] else ...[
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Delete Request',
                    isOutlined: true,
                    color: AppColors.error,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: Text('Delete Request?', style: AppTextStyles.h3),
                          content: Text('Are you sure you want to delete this loan request? This cannot be undone.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Delete', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await FirebaseFirestore.instance.collection(AppConstants.colRequests).doc(requestId).delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request deleted successfully', style: AppTextStyles.caption.copyWith(color: Colors.white)), backgroundColor: AppColors.gold));
                            Navigator.pop(context); // Fallback if context.pop() fails
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting request', style: AppTextStyles.caption.copyWith(color: Colors.white)), backgroundColor: AppColors.error));
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMakeOfferSheet(BuildContext context, String lenderId,
      Map<String, dynamic> requestData, String requestId) {
    showMakeOfferSheet(context, lenderId, requestData, requestId);
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  const _DetailStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.gold)),
        Text(label, style: AppTextStyles.caption),
      ]);
}

class _DetailRow2 extends StatelessWidget {
  final String label, value;
  const _DetailRow2(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          Spacer(),
          Text(value, style: AppTextStyles.labelMedium),
        ]),
      );
}

// ─────────────────────────────────────────────────────
// Make Offer Sheet
// ─────────────────────────────────────────────────────
void showMakeOfferSheet(BuildContext context, String lenderId,
    Map<String, dynamic> requestData, String requestId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MakeOfferSheet(
      lenderId: lenderId,
      requestData: requestData,
      requestId: requestId,
    ),
  );
}

class MakeOfferSheet extends StatefulWidget {
  final String lenderId;
  final String requestId;
  final Map<String, dynamic> requestData;

  const MakeOfferSheet({
    required this.lenderId,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  final _amountCtr = TextEditingController();
  final _rateCtr = TextEditingController();
  final _messageCtr = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to what the borrower requested
    _amountCtr.text = (widget.requestData['loanAmount'] ?? '').toString();
    _rateCtr.text =
        (widget.requestData['maxInterestRatePerMonth'] ?? '').toString();
  }

  @override
  void dispose() {
    _amountCtr.dispose();
    _rateCtr.dispose();
    _messageCtr.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    final amount = double.tryParse(_amountCtr.text) ?? 0;
    final rate = double.tryParse(_rateCtr.text) ?? 0;
    final msg = _messageCtr.text.trim();

    if (amount <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid amount and rate')),
      );
      return;
    }

    // Prevent self-match: a lender cannot send an offer to their own request.
    final borrowerId = widget.requestData['borrowerId'] as String? ?? '';
    if (widget.lenderId == borrowerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot send an offer to your own request.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if match already exists
      final existingMatch = await FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .where('borrowerId', isEqualTo: widget.requestData['borrowerId'])
          .where('lenderId', isEqualTo: widget.lenderId)
          .get();

      if (existingMatch.docs.isNotEmpty) {
        if (context.mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You already have an active chat with this borrower.'),
              backgroundColor: AppColors.info,
            ),
          );
          context.pop();
        }
        return;
      }

      final matchRef =
          FirebaseFirestore.instance.collection(AppConstants.colMatches).doc();
      final chatRoomId = '${matchRef.id}_chat';

      final match = MatchModel(
        id: matchRef.id,
        borrowerId: widget.requestData['borrowerId'],
        lenderId: widget.lenderId,
        requestId: widget.requestId,
        status: MatchStatus.accepted, // Auto-accept to avoid "Waiting for approval"
        chatRoomId: chatRoomId,
        offeredAmount: amount,
        offeredInterestRate: rate,
        offerMessage: msg.isNotEmpty ? msg : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create the match document
      await matchRef.set(match.toMap());

      // Create a notification for the borrower
      await FirebaseFirestore.instance
          .collection('users')
          .doc(match.borrowerId)
          .collection('notifications')
          .add({
        'title': 'New Offer Received! 📬',
        'body': 'A lender has offered ₹${match.offeredAmount} at ${match.offeredInterestRate}%.',
        'type': 'match',
        'isRead': false,
        'createdAt': DateTime.now(),
      });

      // If there is an introductory message, insert it into the chat immediately
      if (msg.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(AppConstants.colChats)
            .doc(chatRoomId)
            .collection(AppConstants.colMessages)
            .add({
          'senderId': widget.lenderId,
          'content': msg,
          'type': MessageType.text.name,
          'isRead': false,
          'sentAt': DateTime.now(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Close sheet
      // Navigate to chat
      context.push('/chat/$chatRoomId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Make an Offer', style: AppTextStyles.h2),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Propose your terms to the borrower. Once sent, a chat will open so you can negotiate directly.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtr,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Offered Amount (₹)',
              hintText: 'e.g. 15000',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rateCtr,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Interest Rate (% per month)',
              hintText: 'e.g. 5',
              prefixIcon: Icon(Icons.percent_rounded),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageCtr,
            maxLines: 3,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Message (Optional)',
              hintText: 'Hi, I can fund this if...',
              prefixIcon: Icon(Icons.message_rounded),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _isLoading ? 'Sending...' : 'Send Offer',
            onPressed: _isLoading ? () {} : _submitOffer,
            icon: _isLoading ? null : Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
