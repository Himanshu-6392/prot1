import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/match_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }
    final uid = authUser.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.bg.withOpacity(0.8),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text('Messages', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                  background: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.colMatches)
                .where('status', isEqualTo: MatchStatus.accepted.name)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snap.error}')));
              if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));

              var docs = snap.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['borrowerId'] == uid || data['lenderId'] == uid;
              }).toList();

              docs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['updatedAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (docs.isEmpty) return SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No conversations yet',
                  subtitle: 'Accept a match to start chatting.',
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              );

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final match = MatchModel.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
                      final isLender = match.lenderId == uid;
                      final peerId   = isLender ? match.borrowerId : match.lenderId;
                      // Staggered animation
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChatTile(match: match, peerId: peerId, isLender: isLender)
                            .animate(delay: (i * 80).ms)
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.05, curve: Curves.easeOutCubic),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final MatchModel match;
  final String peerId;
  final bool isLender;
  const _ChatTile({required this.match, required this.peerId, required this.isLender});

  @override
  Widget build(BuildContext context) {
    // Determine if there are "unread" messages (simulated for now by time proximity)
    final bool hasUnread = DateTime.now().difference(match.updatedAt).inHours < 1;

    return GlassCard(
      onTap: () => context.push('/chat/${match.chatRoomId}'),
      padding: const EdgeInsets.all(16),
      glowOnHover: true,
      borderColor: hasUnread ? AppColors.gold.withOpacity(0.5) : null,
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: isLender ? AppColors.emeraldGradient : AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isLender ? AppColors.emerald : AppColors.gold).withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4)
                    )
                  ]
                ),
                child: Center(
                  child: Text(
                    isLender ? 'B' : 'L',
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                ),
              ),
              // Online dot
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          // Chat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isLender ? 'Borrower ${peerId.substring(0, 4)}' : 'Lender ${peerId.substring(0, 4)}', style: AppTextStyles.h4),
                    Text(AppFormatters.formatRelative(match.updatedAt), style: AppTextStyles.caption.copyWith(color: hasUnread ? AppColors.gold : AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap to view conversation...',
                        style: AppTextStyles.bodyMedium.copyWith(color: hasUnread ? AppColors.textPrimary : AppColors.textMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Chat Room Screen (Premium Redesign)
// ─────────────────────────────────────────────────────
class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});
  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _msgCtr    = TextEditingController();
  final _scrollCtr = ScrollController();
  bool _sending    = false;

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

    setState(() => _sending = true);
    _msgCtr.clear();

    await _messagesRef.add({
      'senderId': authUser.uid,
      'content':  text,
      'type':     MessageType.text.name,
      'isRead':   false,
      'sentAt':   DateTime.now(),
    });
    
    // Update match timestamp so it bumps to top
    FirebaseFirestore.instance
      .collection(AppConstants.colMatches)
      .doc(widget.roomId)
      .update({'updatedAt': FieldValue.serverTimestamp()});

    setState(() => _sending = false);
    
    if (_scrollCtr.hasClients) {
      _scrollCtr.animateTo(
        _scrollCtr.position.minScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: AppColors.bg.withOpacity(0.65),
              elevation: 0,
              centerTitle: true,
              title: Column(children: [
                Text('Chat', style: AppTextStyles.h3),
                Text('Room: ${widget.roomId.substring(0, 8)}', style: AppTextStyles.caption),
              ]),
              actions: [
                IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () => _showChatOptions(context)),
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // We order by descending so list view can be reversed (sticks to bottom)
            stream: _messagesRef.orderBy('sentAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.gold));
              final docs = snap.data!.docs;

              return ListView.builder(
                controller: _scrollCtr,
                reverse: true, // Crucial for modern chat feel (anchors to bottom)
                physics:    const BouncingScrollPhysics(),
                padding:    EdgeInsets.only(left: 16, right: 16, top: MediaQuery.of(context).padding.top + 70, bottom: 20),
                itemCount:  docs.length,
                itemBuilder: (context, i) {
                  final msg  = ChatMessage.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
                  final isMe = msg.senderId == (authUser?.uid ?? '');
                  
                  // Check if we need to show a date divider
                  bool showDate = false;
                  if (i == docs.length - 1) {
                    showDate = true;
                  } else {
                    final prevMsg = ChatMessage.fromMap(docs[i + 1].data() as Map<String, dynamic>, docs[i + 1].id);
                    if (msg.sentAt.day != prevMsg.sentAt.day) showDate = true;
                  }

                  Widget bubble = _MessageBubble(message: msg, isMe: isMe)
                      .animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);

                  if (showDate) {
                    return Column(
                      children: [
                        _DateDivider(date: msg.sentAt).animate().fadeIn(),
                        bubble,
                      ],
                    );
                  }
                  return bubble;
                },
              );
            },
          ),
        ),

        // Floating Glass Input Area
        SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              borderRadius: 32,
              blur: 24,
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.add_rounded, color: AppColors.textPrimary),
                    onPressed: () => _showChatOptions(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _msgCtr,
                    style:      AppTextStyles.bodyMedium,
                    maxLines:   4, minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText:    'Message...',
                      filled:       false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      border:      InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                      ]
                    ),
                    child: _sending
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          _AttachmentOption(icon: Icons.image_rounded, color: AppColors.gold, title: 'Share Photo'),
          _AttachmentOption(icon: Icons.description_rounded, color: AppColors.info, title: 'Document'),
          _AttachmentOption(icon: Icons.location_on_rounded, color: AppColors.emerald, title: 'Location'),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _AttachmentOption({required this.icon, required this.color, required this.title});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTextStyles.labelLarge),
      onTap: () => Navigator.pop(context),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _formatDate(date),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:  const EdgeInsets.only(top: 2, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.goldGradient : null,
          color:    isMe ? null : AppColors.surface,
          border:   isMe ? null : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(20),
            topRight:    const Radius.circular(20),
            bottomLeft:  Radius.circular(isMe ? 20 : 4), // Teardrop effect
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe 
            ? [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isMe ? Colors.white : AppColors.textPrimary,
              )),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppFormatters.formatTime(message.sentAt),
                  style: AppTextStyles.caption.copyWith(
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                    fontSize: 10,
                  )),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
