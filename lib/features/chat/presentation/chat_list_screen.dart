import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colMatches)
            .where('status', isEqualTo: MatchStatus.accepted.name)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

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

          if (docs.isEmpty) return EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No conversations yet',
            subtitle: 'Accept a match to start chatting.',
          );

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: AppColors.border),
            itemBuilder: (context, i) {
              final match = MatchModel.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
              final isLender = match.lenderId == uid;
              final peerId   = isLender ? match.borrowerId : match.lenderId;
              return _ChatTile(match: match, peerId: peerId, isLender: isLender)
                  .animate(delay: Duration(milliseconds: i * 40)).fadeIn();
            },
          );
        },
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: isLender ? AppColors.emeraldGradient : AppColors.goldGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: Icon(
          isLender ? Icons.account_balance_wallet_rounded : Icons.savings_rounded,
          color: Colors.white, size: 22,
        )),
      ),
      title: Text(isLender ? 'Borrower' : 'Lender', style: AppTextStyles.labelLarge),
      subtitle: Text(peerId.substring(0, 12) + '...',
          style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(AppFormatters.formatRelative(match.updatedAt),
          style: AppTextStyles.caption),
      onTap: () => context.push('/chat/${match.chatRoomId}'),
    );
  }
}

// ─────────────────────────────────────────────────────
// Chat Room Screen
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

    setState(() => _sending = false);
    _scrollCtr.animateTo(_scrollCtr.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chat'),
          Text('Room: ${widget.roomId.substring(0, 12)}...', style: AppTextStyles.caption),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.more_vert_rounded), onPressed: () => _showChatOptions(context)),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _messagesRef.orderBy('sentAt').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.gold));
              final docs = snap.data!.docs;

              return ListView.builder(
                controller: _scrollCtr,
                physics:    const BouncingScrollPhysics(),
                padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount:  docs.length,
                itemBuilder: (context, i) {
                  final msg  = ChatMessage.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
                  final isMe = msg.senderId == (authUser?.uid ?? '');
                  return _MessageBubble(message: msg, isMe: isMe)
                      .animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),

        // Input area
        Container(
          padding:    const EdgeInsets.fromLTRB(12, 8, 12, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            IconButton(
              icon: Icon(Icons.attach_file_rounded, color: AppColors.textMuted),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _msgCtr,
                style:      AppTextStyles.bodyMedium,
                maxLines:   5, minLines: 1,
                decoration: InputDecoration(
                  hintText:    'Type a message...',
                  filled:       true,
                  fillColor:    AppColors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border:      OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
                child: _sending
                    ? Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.image_rounded, color: AppColors.gold),
            title: Text('Share Photo', style: AppTextStyles.labelLarge),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: Icon(Icons.attach_file_rounded, color: AppColors.info),
            title: Text('Share Document', style: AppTextStyles.labelLarge),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today_rounded, color: AppColors.emerald),
            title: Text('Schedule Meeting', style: AppTextStyles.labelLarge),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: Icon(Icons.location_on_rounded, color: AppColors.warning),
            title: Text('Share Location', style: AppTextStyles.labelLarge),
            onTap: () { Navigator.pop(context); },
          ),
        ]),
      ),
    );
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
        margin:  const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.goldGradient : null,
          color:    isMe ? null : AppColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: isMe ? [BoxShadow(color: AppColors.gold.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMe ? AppColors.textInverse : AppColors.textPrimary,
              )),
            SizedBox(height: 3),
            Text(AppFormatters.formatTime(message.sentAt),
              style: AppTextStyles.caption.copyWith(
                color: isMe ? AppColors.textInverse.withOpacity(0.7) : AppColors.textMuted,
              )),
          ],
        ),
      ),
    );
  }
}
