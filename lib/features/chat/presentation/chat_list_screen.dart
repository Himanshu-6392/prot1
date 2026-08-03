import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/match_model.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────
String _sectionLabel(DateTime? dt) {
  if (dt == null) return 'Older';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return 'This Week';
  return 'Older';
}



// ─────────────────────────────────────────────────────────────────────────────
// CHAT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [


          // ── Main Content ─────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header (matches Search page exactly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Two-line title
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your',
                                    style: AppTextStyles.h1.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: -1,
                                    )),
                                Text('Messages',
                                    style: AppTextStyles.h1.copyWith(
                                      color: AppColors.gold,
                                      letterSpacing: -1,
                                      height: 1.1,
                                    )),
                              ],
                            ),
                          ),
                          // Filter icon (top-right)
                          GestureDetector(
                            onTap: () => _showOptionsMenu(context),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                    color: AppColors.border.withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.tune_rounded,
                                  color: AppColors.textSecondary, size: 20),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Solid Rounded Search Bar
                      TextField(
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textMuted),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.search_rounded,
                                color: AppColors.gold, size: 24),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),


                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // ── Chat List ───────────────────────────────────────────────
                Expanded(
                  child: _ChatListBody(
                    uid: authUser.uid,
                    filter: 'All',
                    searchQuery: _searchQuery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(title: 'Options', children: [
        _SheetOption(icon: Icons.archive_outlined, label: 'Archived Chats',
            iconColor: AppColors.gold, onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.block_rounded, label: 'Blocked Users',
            iconColor: AppColors.warning, onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.settings_outlined, label: 'Chat Settings',
            iconColor: AppColors.textSecondary, onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}

// ─── Chat List Body ───────────────────────────────────────────────────────────
class _ChatListBody extends ConsumerWidget {
  final String uid;
  final String filter;
  final String searchQuery;

  const _ChatListBody({
    required this.uid,
    required this.filter,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .where('status', whereIn: [
            MatchStatus.pending.name, MatchStatus.accepted.name])
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error', style: TextStyle(color: AppColors.error)));
        }
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        var docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final lId = data['lenderId'] as String? ?? '';
          final bId = data['borrowerId'] as String? ?? '';
          // Must involve this user AND must not be a self-match
          return (lId == uid || bId == uid) && lId != bId && lId.isNotEmpty && bId.isNotEmpty;
        }).toList();

        docs.sort((a, b) {
          final aT = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          final bT = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });

        var matches = docs
            .map((d) => MatchModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();

        if (filter == 'Active') {
          matches = matches.where((m) => m.status == MatchStatus.accepted).toList();
        } else if (filter == 'Pending') {
          matches = matches.where((m) => m.status == MatchStatus.pending).toList();
        }

        if (matches.isEmpty) {
          return _EmptyState(filter: filter);
        }

        // Group by date section
        final Map<String, List<MatchModel>> grouped = {};
        for (final m in matches) {
          final section = _sectionLabel(m.updatedAt);
          grouped.putIfAbsent(section, () => []).add(m);
        }
        final sectionOrder = ['Today', 'Yesterday', 'This Week', 'Older'];
        final sections = sectionOrder.where((s) => grouped.containsKey(s)).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Grouped conversation list
            for (final section in sections) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(label: section),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final match = grouped[section]![i];
                    final isLender = match.lenderId == uid;
                    final peerId = isLender ? match.borrowerId : match.lenderId;

                    if (searchQuery.isNotEmpty) {
                      // Will be filtered inside tile
                    }

                    return _ChatCard(
                      key: ValueKey(match.id),
                      match: match,
                      peerId: peerId,
                      isLender: isLender,
                      searchQuery: searchQuery,
                      index: i,
                    );
                  },
                  childCount: grouped[section]!.length,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        );
      },
    );
  }
}


// ─── Pulsing Online Dot ───────────────────────────────────────────────────────
class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13, height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.emerald,
        border: Border.all(color: Colors.white, width: 2),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
          begin: 1.0, end: 1.3,
          duration: 900.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(begin: 1.3, end: 1.0, duration: 900.ms);
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          )),
    );
  }
}

// ─── Premium Chat Card with Swipe ─────────────────────────────────────────────
class _ChatCard extends ConsumerWidget {
  final MatchModel match;
  final String peerId;
  final bool isLender;
  final String searchQuery;
  final int index;

  const _ChatCard({
    super.key,
    required this.match,
    required this.peerId,
    required this.isLender,
    required this.searchQuery,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peerAsync = ref.watch(userProfileProvider(peerId));

    return peerAsync.when(
      data: (peer) {
        final name = peer?.name ?? (isLender ? 'Borrower' : 'Lender');
        final dp = peer?.photoUrl;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final isPending = match.status == MatchStatus.pending;

        if (searchQuery.isNotEmpty &&
            !name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return Dismissible(
          key: ValueKey('dismiss_${match.id}'),
          // ── Swipe RIGHT → Mark Unread ──────────────────────────────────
          background: Container(
            color: AppColors.gold,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_chat_unread_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text('Unread',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // ── Swipe LEFT → Delete ────────────────────────────────────────
          secondaryBackground: Container(
            color: AppColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text('Delete',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await _confirmDelete(context);
            }
            // Mark unread — just visual feedback for now
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Marked as unread'),
                backgroundColor: AppColors.gold,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            return false;
          },
          onDismissed: (_) {
            FirebaseFirestore.instance
                .collection(AppConstants.colMatches)
                .doc(match.id)
                .delete();
          },

          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showContextMenu(context, ref);
            },
            child: Material(
              color: AppColors.surface,
              child: InkWell(
                onTap: () =>
                    context.push('/chat/${match.chatRoomId}', extra: peer),
                splashColor: AppColors.emerald.withValues(alpha: 0.04),
                highlightColor: AppColors.emerald.withValues(alpha: 0.02),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    children: [
                        // ── Avatar ──────────────────────────────────────
                        Stack(
                          children: [
                            Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dp == null ? Colors.white : null,
                                border: dp == null 
                                    ? Border.all(color: AppColors.textPrimary, width: 1.5)
                                    : null,
                                image: dp != null
                                    ? DecorationImage(
                                        image: NetworkImage(dp),
                                        fit: BoxFit.cover)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10, offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: dp == null
                                  ? Center(child: Text(initial,
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600)))
                                  : null,
                            ),
                            // Status dot
                            Positioned(
                              right: 1, bottom: 1,
                              child: isPending
                                  ? Container(
                                      width: 13, height: 13,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.warning,
                                        border: Border.all(
                                            color: AppColors.surface, width: 2),
                                      ),
                                    )
                                  : _PulsingDot(),
                            ),
                          ],
                        ),

                        const SizedBox(width: 14),

                        // ── Content ─────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + time row
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(children: [
                                      Flexible(
                                        child: Text(name,
                                            style: AppTextStyles.labelLarge.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isLender ? AppColors.gold : AppColors.emerald)
                                              .withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isLender ? 'Borrower' : 'Lender',
                                          style: TextStyle(
                                            color: isLender
                                                ? AppColors.gold
                                                : AppColors.emerald,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                  Text(
                                    AppFormatters.formatRelative(match.updatedAt),
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Preview + badge row
                              Row(
                                children: [
                                  Expanded(
                                    child: isPending
                                        ? Row(children: [
                                            Icon(Icons.schedule_rounded,
                                                size: 12, color: AppColors.warning),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                isLender
                                                    ? 'Incoming request...'
                                                    : 'Awaiting reply...',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.warning,
                                                  fontSize: 12.5,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ])
                                        : StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection(AppConstants.colChats)
                                                .doc(match.chatRoomId)
                                                .collection(AppConstants.colMessages)
                                                .orderBy('sentAt', descending: true)
                                                .limit(1)
                                                .snapshots(),
                                            builder: (context, msgSnap) {
                                              String preview = 'Start the conversation';
                                              bool unread = false;
                                              bool isMine = false;
                                              String? msgType;

                                              if (msgSnap.hasData &&
                                                  msgSnap.data!.docs.isNotEmpty) {
                                                final doc = msgSnap.data!.docs.first
                                                    .data() as Map<String, dynamic>;
                                                preview = doc['content'] as String? ?? 'Message';
                                                msgType = doc['type'] as String?;
                                                final currentUid = ref
                                                    .read(authStateProvider)
                                                    .valueOrNull
                                                    ?.uid;
                                                isMine = doc['senderId'] == currentUid;
                                                unread = !isMine && (doc['isRead'] == false);
                                              }

                                              // Media icon
                                              IconData? mediaIcon;
                                              String? mediaLabel;
                                              if (msgType == 'image') {
                                                mediaIcon = Icons.image_outlined;
                                                mediaLabel = 'Photo';
                                              } else if (msgType == 'document') {
                                                mediaIcon = Icons.attach_file_rounded;
                                                mediaLabel = 'Document';
                                              }

                                              return Row(children: [
                                                if (isMine) ...[
                                                  Icon(Icons.done_all_rounded,
                                                      size: 14, color: AppColors.emerald),
                                                  const SizedBox(width: 3),
                                                ],
                                                if (mediaIcon != null) ...[
                                                  Icon(mediaIcon,
                                                      size: 13,
                                                      color: AppColors.textMuted),
                                                  const SizedBox(width: 3),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    mediaLabel ?? preview,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: unread
                                                          ? AppColors.textPrimary
                                                          : AppColors.textSecondary,
                                                      fontSize: 13,
                                                      fontWeight: unread
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ]);
                                            },
                                          ),
                                  ),

                                  // Unread badge
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection(AppConstants.colChats)
                                        .doc(match.chatRoomId)
                                        .collection(AppConstants.colMessages)
                                        .where('isRead', isEqualTo: false)
                                        .where('senderId',
                                            isNotEqualTo: ref
                                                    .read(authStateProvider)
                                                    .valueOrNull
                                                    ?.uid ?? '')
                                        .snapshots(),
                                    builder: (ctx, unreadSnap) {
                                      final count = unreadSnap.data?.docs.length ?? 0;
                                      if (count == 0) return const SizedBox.shrink();
                                      return Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.gold.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          count > 99 ? '99+' : '$count',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted.withValues(alpha: 0.4), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: index * 50))
              .fadeIn(duration: 280.ms)
              .slideX(begin: 0.03, end: 0, curve: Curves.easeOut);
      },

      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Container(width: 54, height: 54,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.surfaceAlt)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 13, width: 130,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 11, width: 200,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6))),
            ],
          )),
        ]),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1.2.seconds, color: AppColors.surfaceHigh),

      error: (_, __) => const SizedBox(height: 74),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Chat', style: AppTextStyles.h3),
        content: Text(
          'This chat will be permanently deleted.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(title: 'Chat Options', children: [
        _SheetOption(icon: Icons.mark_chat_unread_outlined,
            label: 'Mark as Unread', iconColor: AppColors.gold,
            onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.notifications_off_outlined,
            label: 'Mute Notifications', iconColor: AppColors.textSecondary,
            onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.archive_outlined,
            label: 'Archive Chat', iconColor: AppColors.info,
            onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.block_rounded,
            label: 'Block User', iconColor: AppColors.warning,
            onTap: () => Navigator.pop(context)),
        _SheetOption(icon: Icons.delete_outline_rounded,
            label: 'Delete Chat', iconColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context).then((confirmed) {
                if (confirmed == true) {
                  FirebaseFirestore.instance
                      .collection(AppConstants.colMatches)
                      .doc(match.id)
                      .delete();
                }
              });
            }),
      ]),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> config = {
      'All': {'icon': Icons.chat_bubble_outline_rounded,
          'title': 'No conversations yet',
          'subtitle': 'Your matches will appear here once connected.'},
      'Unread': {'icon': Icons.mark_chat_read_outlined,
          'title': 'All caught up!',
          'subtitle': 'No unread messages at the moment.'},
      'Active': {'icon': Icons.handshake_outlined,
          'title': 'No active deals',
          'subtitle': 'Accept a match request to start chatting.'},
      'Pending': {'icon': Icons.schedule_rounded,
          'title': 'No pending requests',
          'subtitle': 'Send or receive a match request to see them here.'},
    };
    final c = config[filter] ?? config['All']!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(c['icon'] as IconData,
                  color: AppColors.textMuted, size: 36),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .scaleXY(begin: 1, end: 1.04, duration: 1.5.seconds,
                    curve: Curves.easeInOut)
                .then()
                .scaleXY(begin: 1.04, end: 1, duration: 1.5.seconds),
            const SizedBox(height: 20),
            Text(c['title'] as String,
                style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(c['subtitle'] as String,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({super.key, required this.focusNode,
      required this.onChanged, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 3),
            )],
          ),
          child: Row(children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                focusNode: focusNode,
                onChanged: onChanged,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: onClose,
        child: Text('Cancel',
            style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gold, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

// ─── Header Icon Button ────────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _BottomSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3.copyWith(
              fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Divider(color: AppColors.border, height: 1),
          ...children,
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ─── Sheet Option ──────────────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _SheetOption({required this.icon, required this.label,
      required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary, fontSize: 14.5,
              fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5), size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT ROOM SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final UserModel? peerUser;
  const ChatRoomScreen({super.key, required this.roomId, this.peerUser});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgCtr = TextEditingController();
  final _scrollCtr = ScrollController();
  bool _sending = false;
  bool _hasText = false;
  bool _uploading = false;
  double _uploadProgress = 0.0;

  Future<void> _sharePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    
    await _uploadMedia(picked.path, await picked.readAsBytes(), MessageType.image, picked.name);
  }

  Future<void> _shareDocument() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    
    final file = result.files.first;
    final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null) return;
    
    await _uploadMedia(file.path ?? file.name, bytes, MessageType.document, file.name);
  }

  Future<void> _uploadMedia(String path, Uint8List bytes, MessageType type, String fileName) async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : (type == MessageType.image ? 'jpg' : 'bin');
      final mediaId = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('chat_media/${widget.roomId}/$mediaId.$ext');
      
      final uploadTask = ref.putData(bytes);
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await _messagesRef.add({
        'senderId': authUser.uid,
        'content': type == MessageType.image ? 'Sent a photo' : 'Sent a document',
        'type': type.name,
        'mediaUrl': url,
        'fileName': fileName,
        'isRead': false,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
        if (_scrollCtr.hasClients) {
          _scrollCtr.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      }
    }
  }

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      FirebaseFirestore.instance
          .collection(AppConstants.colChats)
          .doc(widget.roomId)
          .collection(AppConstants.colMessages);

  Future<void> _send() async {
    final text = _msgCtr.text.trim();
    if (text.isEmpty) return;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() { _sending = true; _hasText = false; });
    _msgCtr.clear();

    await _messagesRef.add({
      'senderId': authUser.uid,
      'content': text,
      'type': MessageType.text.name,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });

    setState(() => _sending = false);
    if (_scrollCtr.hasClients) {
      _scrollCtr.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _msgCtr.dispose();
    _scrollCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final name = widget.peerUser?.name ?? 'Private Message';
    final dp = widget.peerUser?.photoUrl;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leadingWidth: 30,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dp == null ? Colors.white : null,
              border: dp == null
                  ? Border.all(color: AppColors.textPrimary, width: 1.5)
                  : null,
              image: dp != null
                  ? DecorationImage(image: NetworkImage(dp), fit: BoxFit.cover)
                  : null,
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: dp == null
                ? Center(child: Text(initial, style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)))
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: AppTextStyles.labelLarge.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Row(children: [
                _PulsingDot().animate().custom(
                  duration: 0.ms, builder: (_, __, child) => SizedBox(
                    width: 7, height: 7, child: child)),
                const SizedBox(width: 4),
                Text('Online', style: AppTextStyles.caption.copyWith(
                    color: AppColors.emerald, fontSize: 11.5)),
              ]),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Column(children: [
        if (_uploading) LinearProgressIndicator(value: _uploadProgress, color: AppColors.gold, backgroundColor: AppColors.surfaceAlt),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _messagesRef.orderBy('sentAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator(color: AppColors.gold));
              }
              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_rounded, color: AppColors.gold, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('Say hello! 👋', style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Messages are private and secure.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                  ]),
                );
              }

              return ListView.builder(
                controller: _scrollCtr,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final msg = ChatMessage.fromMap(
                      docs[i].data() as Map<String, dynamic>, docs[i].id);
                  final isMe = msg.senderId == (authUser?.uid ?? '');
                  final showDate = i == docs.length - 1;

                  return Column(children: [
                    if (showDate) _DateDivider(label: 'Today'),
                    _MessageBubble(message: msg, isMe: isMe)
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .scale(begin: const Offset(0.94, 0.94),
                            end: const Offset(1, 1), duration: 200.ms,
                            curve: Curves.easeOutBack),
                  ]);
                },
              );
            },
          ),
        ),
        _buildInputBar(context),
      ]),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12, offset: const Offset(0, -2),
        )],
      ),
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _msgCtr,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary),
                      maxLines: 5, minLines: 1,
                      onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: Icon(Icons.emoji_emotions_outlined,
                        color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: 200.ms,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                        boxShadow: [BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: _sending
                          ? const Padding(padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    key: const ValueKey('mic'),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: AppColors.surfaceAlt),
                    child: Icon(Icons.mic_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(title: 'Chat Options', children: [
        _SheetOption(icon: Icons.image_outlined, label: 'Share Photo',
            iconColor: AppColors.info,
            onTap: () { Navigator.pop(context); _sharePhoto(); }),
        _SheetOption(icon: Icons.attach_file_rounded, label: 'Share Document',
            iconColor: AppColors.gold,
            onTap: () { Navigator.pop(context); _shareDocument(); }),

        _SheetOption(icon: Icons.delete_outline_rounded, label: 'Delete Chat',
            iconColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Delete Chat', style: AppTextStyles.h3),
                  content: Text('This cannot be undone.',
                      style: AppTextStyles.bodyMedium),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection(AppConstants.colMatches)
                            .doc(widget.roomId)
                            .delete();
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            }),
      ]),
    );
  }
}

// ─── Date Divider ──────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(label, style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted, fontSize: 11.5,
              fontWeight: FontWeight.w600,
            )),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, height: 1)),
      ]),
    );
  }
}

// ─── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3, bottom: 3,
          left: isMe ? 52 : 0,
          right: isMe ? 0 : 52,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.gold.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isMe
                ? AppColors.gold.withValues(alpha: 0.15)
                : AppColors.border.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.type == MessageType.image && message.mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(message.mediaUrl!, width: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 6),
            ] else if (message.type == MessageType.document && message.mediaUrl != null) ...[
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Icon(Icons.insert_drive_file_rounded, color: AppColors.gold, size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: Text(message.fileName ?? 'Document', 
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary), 
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              Text(message.content, style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary, fontSize: 14.5, height: 1.4,
              )),
              const SizedBox(height: 4),
            ],
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(AppFormatters.formatTime(message.sentAt),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted, fontSize: 10.5)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all_rounded, size: 13, color: AppColors.emerald),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
