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

// ─── Chat Purple Accent ───────────────────────────────────────────────────────
const _kPurple = Color(0xFF7C3AED);

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
  String _activeFilter = 'All';
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _kPurple)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.more_horiz_rounded,
                      color: Color(0xFF1A1A1A), size: 26),
                  const Spacer(),
                  const Text('Messages',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      )),
                  const Spacer(),
                  Row(children: [
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.search_rounded,
                          color: Color(0xFF1A1A1A), size: 24),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () {},
                      child: const Icon(Icons.add_rounded,
                          color: Color(0xFF1A1A1A), size: 26),
                    ),
                  ]),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ── Filter Tabs ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Chats', 'Groups'].map((tab) {
                  final isActive = _activeFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeFilter = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tab,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 4),

            // ── Chat List ─────────────────────────────────────────────
            Expanded(
              child: _ChatListBody(
                uid: authUser.uid,
                filter: _activeFilter,
                searchQuery: _searchQuery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Row ───────────────────────────────────────────────────────────────
class _StatusRow extends ConsumerWidget {
  final String uid;
  const _StatusRow({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(userProfileProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Text('Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                )),
            const Spacer(),
            const Icon(Icons.more_horiz_rounded,
                color: Color(0xFF999999), size: 20),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF999999), size: 20),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _StatusAvatar(
                label: 'My Status',
                photoUrl: meAsync.valueOrNull?.photoUrl,
                initial: meAsync.valueOrNull?.name.isNotEmpty == true
                    ? meAsync.valueOrNull!.name[0].toUpperCase()
                    : 'M',
                isMe: true,
              ),
              const _StatusAvatar(
                  label: 'Mr. Ayo', initial: 'A',
                  bgColor: Color(0xFFFFB3C1)),
              const _StatusAvatar(
                  label: 'Hero Anne', initial: 'H',
                  bgColor: Color(0xFFB3D9FF)),
              const _StatusAvatar(
                  label: 'Porkoo H.', initial: 'P',
                  bgColor: Color(0xFFB3FFD1)),
              const _StatusAvatar(
                  label: 'Aura Ak.', initial: 'K',
                  bgColor: Color(0xFFFFE0B3)),
              const _StatusAvatar(
                  label: 'Walter H.', initial: 'W',
                  bgColor: Color(0xFFE0B3FF)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Status Avatar ────────────────────────────────────────────────────────────
class _StatusAvatar extends StatelessWidget {
  final String label;
  final String? photoUrl;
  final String initial;
  final bool isMe;
  final Color? bgColor;

  const _StatusAvatar({
    required this.label,
    required this.initial,
    this.photoUrl,
    this.isMe = false,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFFE040FB),
                        Color(0xFF7C4DFF),
                        Color(0xFF2196F3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: isMe
                  ? Border.all(color: const Color(0xFFDDDDDD), width: 2.5)
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor ?? const Color(0xFFF0F0F0),
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: photoUrl == null
                  ? Center(
                      child: Text(initial,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isMe
                                ? const Color(0xFF999999)
                                : Colors.white.withValues(alpha: 0.95),
                          )))
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
            MatchStatus.pending.name,
            MatchStatus.accepted.name
          ])
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text('Error',
                  style: TextStyle(color: AppColors.error)));
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _kPurple));
        }

        var docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final lId = data['lenderId'] as String? ?? '';
          final bId = data['borrowerId'] as String? ?? '';
          return (lId == uid || bId == uid) &&
              lId != bId &&
              lId.isNotEmpty &&
              bId.isNotEmpty;
        }).toList();

        docs.sort((a, b) {
          final aT =
              (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          final bT =
              (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
          if (aT == null || bT == null) return 0;
          return bT.compareTo(aT);
        });

        var matches = docs
            .map((d) =>
                MatchModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();

        if (filter == 'Active') {
          matches = matches
              .where((m) => m.status == MatchStatus.accepted)
              .toList();
        } else if (filter == 'Pending') {
          matches = matches
              .where((m) => m.status == MatchStatus.pending)
              .toList();
        }

        if (matches.isEmpty) {
          return _EmptyState(filter: filter);
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: matches.length + 1,
          itemBuilder: (context, i) {
            if (i == matches.length) return const SizedBox(height: 110);
            final match = matches[i];
            final isLender = match.lenderId == uid;
            final peerId =
                isLender ? match.borrowerId : match.lenderId;
            return _ChatCard(
              key: ValueKey(match.id),
              match: match,
              peerId: peerId,
              isLender: isLender,
              searchQuery: searchQuery,
              index: i,
            );
          },
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
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.emerald,
        border: Border.all(color: Colors.white, width: 2),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
            begin: 1.0,
            end: 1.3,
            duration: 900.ms,
            curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.3, end: 1.0, duration: 900.ms);
  }
}

// ─── Chat Card ────────────────────────────────────────────────────────────────
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
          background: Container(
            color: _kPurple,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_chat_unread_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(height: 4),
                const Text('Unread',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
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
                const Text('Delete',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await _confirmDelete(context);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Marked as unread'),
                backgroundColor: _kPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            child: InkWell(
              onTap: () =>
                  context.push('/chat/${match.chatRoomId}', extra: peer),
              splashColor: _kPurple.withValues(alpha: 0.04),
              highlightColor: _kPurple.withValues(alpha: 0.02),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // ── Avatar with gradient ring ───────────────────
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: !isPending
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE040FB),
                                      Color(0xFF7C4DFF),
                                      Color(0xFF2196F3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isPending
                                ? const Color(0xFFEEEEEE)
                                : null,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              image: dp != null
                                  ? DecorationImage(
                                      image: NetworkImage(dp),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: dp == null
                                ? Center(
                                    child: Text(initial,
                                        style: const TextStyle(
                                          color: Color(0xFF1A1A1A),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        )))
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: isPending
                              ? Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.warning,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                )
                              : _PulsingDot(),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // ── Text content ─────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + time row
                          Row(children: [
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppFormatters.formatRelative(match.updatedAt),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 4),

                          // Preview + badge row
                          Row(children: [
                            Expanded(
                              child: isPending
                                  ? Row(children: [
                                      const Icon(Icons.schedule_rounded,
                                          size: 12, color: Color(0xFFFAAD14)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          isLender
                                              ? 'Incoming request...'
                                              : 'Awaiting reply...',
                                          style: const TextStyle(
                                            color: Color(0xFFFAAD14),
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ])
                                  : StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection(AppConstants.colChats)
                                          .doc(match.chatRoomId)
                                          .collection(
                                              AppConstants.colMessages)
                                          .orderBy('sentAt',
                                              descending: true)
                                          .limit(1)
                                          .snapshots(),
                                      builder: (context, msgSnap) {
                                        String preview =
                                            'Start the conversation';
                                        bool unread = false;
                                        bool isMine = false;
                                        String? msgType;

                                        if (msgSnap.hasData &&
                                            msgSnap.data!.docs.isNotEmpty) {
                                          final doc = msgSnap.data!.docs
                                                  .first
                                                  .data()
                                              as Map<String, dynamic>;
                                          preview = doc['content']
                                                  as String? ??
                                              'Message';
                                          msgType = doc['type'] as String?;
                                          final currentUid = ref
                                              .read(authStateProvider)
                                              .valueOrNull
                                              ?.uid;
                                          isMine =
                                              doc['senderId'] == currentUid;
                                          unread = !isMine &&
                                              (doc['isRead'] == false);
                                        }

                                        IconData? mediaIcon;
                                        String? mediaLabel;
                                        if (msgType == 'image') {
                                          mediaIcon = Icons.image_outlined;
                                          mediaLabel = 'Photo';
                                        } else if (msgType == 'document') {
                                          mediaIcon =
                                              Icons.attach_file_rounded;
                                          mediaLabel = 'Document';
                                        }

                                        return Row(children: [
                                          if (isMine) ...[
                                            Icon(Icons.done_all_rounded,
                                                size: 14,
                                                color: unread
                                                    ? _kPurple
                                                    : const Color(
                                                        0xFF999999)),
                                            const SizedBox(width: 3),
                                          ],
                                          if (mediaIcon != null) ...[
                                            Icon(mediaIcon,
                                                size: 13,
                                                color:
                                                    const Color(0xFF999999)),
                                            const SizedBox(width: 3),
                                          ],
                                          Expanded(
                                            child: Text(
                                              mediaLabel ?? preview,
                                              style: TextStyle(
                                                color: unread
                                                    ? const Color(0xFF1A1A1A)
                                                    : const Color(0xFF999999),
                                                fontSize: 13,
                                                fontWeight: unread
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]);
                                      },
                                    ),
                            ),

                            // ── Unread badge — PURPLE ───────────────
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
                                              ?.uid ??
                                          '')
                                  .snapshots(),
                              builder: (ctx, unreadSnap) {
                                final count =
                                    unreadSnap.data?.docs.length ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _kPurple,
                                    borderRadius: BorderRadius.circular(10),
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
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn(duration: 280.ms)
            .slideX(begin: 0.03, end: 0, curve: Curves.easeOut);
      },

      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(children: [
          Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFF0F0F0))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 13,
                  width: 130,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(
                  height: 11,
                  width: 200,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6))),
            ],
          )),
        ]),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
              duration: 1.2.seconds, color: const Color(0xFFE8E8E8)),

      error: (_, __) => const SizedBox(height: 74),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Chat',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('This chat will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style:
                      TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
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
        _SheetOption(
            icon: Icons.mark_chat_unread_outlined,
            label: 'Mark as Unread',
            iconColor: _kPurple,
            onTap: () => Navigator.pop(context)),
        _SheetOption(
            icon: Icons.notifications_off_outlined,
            label: 'Mute Notifications',
            iconColor: AppColors.textSecondary,
            onTap: () => Navigator.pop(context)),
        _SheetOption(
            icon: Icons.archive_outlined,
            label: 'Archive Chat',
            iconColor: AppColors.info,
            onTap: () => Navigator.pop(context)),
        _SheetOption(
            icon: Icons.block_rounded,
            label: 'Block User',
            iconColor: AppColors.warning,
            onTap: () => Navigator.pop(context)),
        _SheetOption(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Chat',
            iconColor: AppColors.error,
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
      'All': {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'No conversations yet',
        'subtitle': 'Your matches will appear here once connected.'
      },
      'Chats': {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'No chats yet',
        'subtitle': 'Start a conversation with your matches.'
      },
      'Groups': {
        'icon': Icons.group_outlined,
        'title': 'No groups yet',
        'subtitle': 'Group chats will appear here.'
      },
      'Unread': {
        'icon': Icons.mark_chat_read_outlined,
        'title': 'All caught up!',
        'subtitle': 'No unread messages at the moment.'
      },
      'Active': {
        'icon': Icons.handshake_outlined,
        'title': 'No active deals',
        'subtitle': 'Accept a match request to start chatting.'
      },
      'Pending': {
        'icon': Icons.schedule_rounded,
        'title': 'No pending requests',
        'subtitle': 'Send or receive a match request to see them here.'
      },
    };
    final c = config[filter] ?? config['All']!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPurple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(c['icon'] as IconData,
                  color: _kPurple, size: 36),
            )
                .animate(onPlay: (ctrl) => ctrl.repeat())
                .scaleXY(
                    begin: 1,
                    end: 1.04,
                    duration: 1.5.seconds,
                    curve: Curves.easeInOut)
                .then()
                .scaleXY(begin: 1.04, end: 1, duration: 1.5.seconds),
            const SizedBox(height: 20),
            Text(c['title'] as String,
                style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(c['subtitle'] as String,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(title,
              style: AppTextStyles.h3
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFEEEEEE), height: 1),
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
  const _SheetOption(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 18),
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
  const ChatRoomScreen(
      {super.key, required this.roomId, this.peerUser});

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
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    await _uploadMedia(picked.path, await picked.readAsBytes(),
        MessageType.image, picked.name);
  }

  Future<void> _shareDocument() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes ??
        (file.path != null
            ? await File(file.path!).readAsBytes()
            : null);
    if (bytes == null) return;
    await _uploadMedia(
        file.path ?? file.name, bytes, MessageType.document, file.name);
  }

  Future<void> _uploadMedia(String path, Uint8List bytes,
      MessageType type, String fileName) async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final ext = fileName.contains('.')
          ? fileName.split('.').last
          : (type == MessageType.image ? 'jpg' : 'bin');
      final mediaId = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media/${widget.roomId}/$mediaId.$ext');
      final uploadTask = ref.putData(bytes);
      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress =
              event.bytesTransferred / event.totalBytes;
        });
      });
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      await _messagesRef.add({
        'senderId': authUser.uid,
        'content': type == MessageType.image
            ? 'Sent a photo'
            : 'Sent a document',
        'type': type.name,
        'mediaUrl': url,
        'fileName': fileName,
        'isRead': false,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
        if (_scrollCtr.hasClients) {
          _scrollCtr.animateTo(0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
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

    setState(() {
      _sending = true;
      _hasText = false;
    });
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leadingWidth: 36,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        title: Row(children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dp == null ? const Color(0xFFF0F0F0) : null,
              image: dp != null
                  ? DecorationImage(
                      image: NetworkImage(dp), fit: BoxFit.cover)
                  : null,
            ),
            child: dp == null
                ? Center(
                    child: Text(initial,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        )))
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
              Row(children: [
                _PulsingDot().animate().custom(
                    duration: 0.ms,
                    builder: (_, __, child) =>
                        SizedBox(width: 7, height: 7, child: child)),
                const SizedBox(width: 4),
                Text('Online',
                    style: TextStyle(
                        color: AppColors.emerald, fontSize: 11.5)),
              ]),
            ],
          ),
        ]),
        // ── Video + Phone action icons ────────────────────────────────
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: Color(0xFF888888), size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: Color(0xFF888888), size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [
        if (_uploading)
          LinearProgressIndicator(
              value: _uploadProgress,
              color: _kPurple,
              backgroundColor: const Color(0xFFEEEEEE)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _messagesRef
                .orderBy('sentAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: _kPurple));
              }
              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kPurple.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: _kPurple, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('Say hello! 👋',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 6),
                        const Text(
                            'Messages are private and secure.',
                            style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 13)),
                      ]),
                );
              }

              return ListView.builder(
                controller: _scrollCtr,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final msg = ChatMessage.fromMap(
                      docs[i].data() as Map<String, dynamic>,
                      docs[i].id);
                  final isMe =
                      msg.senderId == (authUser?.uid ?? '');
                  final showDate = i == docs.length - 1;

                  return Column(children: [
                    if (showDate) const _DateDivider(label: 'Today'),
                    _MessageBubble(message: msg, isMe: isMe)
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .scale(
                            begin: const Offset(0.94, 0.94),
                            end: const Offset(1, 1),
                            duration: 200.ms,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, -2))
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Text input with attachment icon ───────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _msgCtr,
                      style: const TextStyle(
                          color: Color(0xFF1A1A1A), fontSize: 14.5),
                      maxLines: 5,
                      minLines: 1,
                      onChanged: (v) => setState(
                          () => _hasText = v.trim().isNotEmpty),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 14.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Attachment icon
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: const Padding(
                      padding:
                          EdgeInsets.only(right: 12, bottom: 10),
                      child: Icon(Icons.attach_file_rounded,
                          color: Color(0xFF999999), size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Send button — PURPLE ──────────────────────────────────
          GestureDetector(
            onTap: _hasText ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasText
                    ? _kPurple
                    : const Color(0xFFEEEEEE),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                            color: _kPurple.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.send_rounded,
                      color: _hasText
                          ? Colors.white
                          : const Color(0xFFBBBBBB),
                      size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(title: 'Share', children: [
        _SheetOption(
            icon: Icons.image_outlined,
            label: 'Share Photo',
            iconColor: _kPurple,
            onTap: () {
              Navigator.pop(context);
              _sharePhoto();
            }),
        _SheetOption(
            icon: Icons.attach_file_rounded,
            label: 'Share Document',
            iconColor: AppColors.gold,
            onTap: () {
              Navigator.pop(context);
              _shareDocument();
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble(
      {required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Sent = purple, Received = white
          color: isMe ? _kPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Image message
            if (message.type == MessageType.image &&
                message.mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(message.mediaUrl!,
                    width: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 6),
            ]
            // Document message
            else if (message.type == MessageType.document &&
                message.mediaUrl != null) ...[
              GestureDetector(
                onTap: () => launchUrl(
                    Uri.parse(message.mediaUrl!),
                    mode: LaunchMode.externalApplication),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.insert_drive_file_rounded,
                        color: isMe ? Colors.white : _kPurple,
                        size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            message.fileName ?? 'Document',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
            ]
            // Text message
            else ...[
              Text(
                message.content,
                style: TextStyle(
                  // White text on purple, dark text on white
                  color: isMe
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Timestamp + read receipt
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                AppFormatters.formatTime(message.sentAt),
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF999999),
                  fontSize: 10.5,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(Icons.done_all_rounded,
                    size: 13,
                    color:
                        Colors.white.withValues(alpha: 0.85)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

