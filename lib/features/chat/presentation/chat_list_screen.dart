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
import '../../../models/user_model.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/match_model.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Active'];

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }
    final uid = authUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFF1), // Light premium grey background similar to the image
      body: Stack(
        children: [
          // Background subtle gradients for the premium feel
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Messages',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Search Bar
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: AppTextStyles.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Search chats, names...',
                                    hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Filters
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filters.length,
                            itemBuilder: (context, i) {
                              final filter = _filters[i];
                              final isSelected = _selectedFilter == filter;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedFilter = filter),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isSelected 
                                        ? Border.all(color: AppColors.textPrimary, width: 1.5)
                                        : Border.all(color: Colors.transparent, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  ),
                                  child: Row(
                                    children: [
                                      if (filter == 'Verified Only') ...[
                                        Icon(Icons.verified, size: 14, color: AppColors.textPrimary),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        filter,
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(AppConstants.colMatches)
                      .where('status', whereIn: [
                    MatchStatus.pending.name,
                    MatchStatus.accepted.name
                  ]).snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text('Error loading messages')),
                      );
                    }
                    if (!snap.hasData) {
                      return const SliverToBoxAdapter(
                        child: Center(
                            child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        )),
                      );
                    }

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

                    final matches = docs
                        .map((d) => MatchModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                        .toList();

                    // Apply filters
                    var filteredMatches = matches;
                    if (_selectedFilter == 'Pending') {
                      filteredMatches = filteredMatches.where((m) => m.status == MatchStatus.pending).toList();
                    } else if (_selectedFilter == 'Active') {
                      filteredMatches = filteredMatches.where((m) => m.status == MatchStatus.accepted).toList();
                    }

                    if (filteredMatches.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No conversations',
                          subtitle: 'Your matches will appear here.',
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 40, left: 24, right: 24),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: filteredMatches.length,
                              separatorBuilder: (context, i) => Divider(height: 1, color: AppColors.border.withOpacity(0.4), indent: 80, endIndent: 20),
                              itemBuilder: (context, i) {
                                final match = filteredMatches[i];
                                final isLender = match.lenderId == uid;
                                final peerId = isLender ? match.borrowerId : match.lenderId;
                                return _ChatTile(
                                  match: match,
                                  peerId: peerId,
                                  isLender: isLender,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Minimal Chat Tile ─────────────────────────────────────────────────────────

class _ChatTile extends ConsumerWidget {
  final MatchModel match;
  final String peerId;
  final bool isLender;
  
  const _ChatTile({
    required this.match,
    required this.peerId,
    required this.isLender,
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
        
        final query = context.findAncestorStateOfType<_ChatListScreenState>()?._searchQuery.toLowerCase() ?? '';
        if (query.isNotEmpty && !name.toLowerCase().contains(query)) {
          return const SizedBox.shrink();
        }

        return Dismissible(
          key: Key(match.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          confirmDismiss: (dir) async {
             return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: const Text('Are you sure you want to delete this chat? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ]
                )
             );
          },
          onDismissed: (dir) {
             FirebaseFirestore.instance.collection(AppConstants.colMatches).doc(match.id).delete();
          },
          child: InkWell(
            onTap: () => context.push('/chat/${match.chatRoomId}', extra: peer),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Minimal Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3F4F6),
                      image: dp != null ? DecorationImage(image: NetworkImage(dp), fit: BoxFit.cover) : null,
                    ),
                    child: dp == null ? Center(
                      child: Text(initial, style: AppTextStyles.h2.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary))
                    ) : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              AppFormatters.formatRelative(match.updatedAt),
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isPending)
                              Expanded(
                                child: Text(
                                  (isLender ? 'Incoming loan request...' : 'Waiting for approval...'),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
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
                                    if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                                      final doc = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
                                      preview = doc['content'] as String? ?? 'Message';
                                      final currentUid = ref.read(authStateProvider).valueOrNull?.uid;
                                      final isMine = doc['senderId'] == currentUid;
                                      unread = !isMine && (doc['isRead'] == false);
                                    }
                                    return Text(
                                      preview,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: unread ? AppColors.textPrimary : AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            if (isPending) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold,
                                ),
                              )
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 84),
      error: (_, __) => const SizedBox(height: 84),
    );
  }
}

// ─────────────────────────────────────────────────────
// Chat Room Screen
// ─────────────────────────────────────────────────────
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
      'content': text,
      'type': MessageType.text.name,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });

    setState(() => _sending = false);
    _scrollCtr.animateTo(0.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (widget.peerUser?.photoUrl != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.peerUser!.photoUrl!),
              ),
              const SizedBox(width: 12),
            ] else ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.emerald,
                child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
            ],
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.peerUser?.name ?? 'Private Message', style: AppTextStyles.h3.copyWith(fontSize: 16)),
              if (widget.peerUser != null)
                Text('Online', style: AppTextStyles.caption.copyWith(color: AppColors.emerald)),
            ]),
          ],
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.more_vert_rounded),
              onPressed: () => _showChatOptions(context)),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _messagesRef.orderBy('sentAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData)
                return Center(
                    child: CircularProgressIndicator(color: AppColors.gold));
              final docs = snap.data!.docs;

              return ListView.builder(
                controller: _scrollCtr,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final msg = ChatMessage.fromMap(
                      docs[i].data() as Map<String, dynamic>, docs[i].id);
                  final isMe = msg.senderId == (authUser?.uid ?? '');
                  return _MessageBubble(message: msg, isMe: isMe)
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.1, end: 0);
                },
              );
            },
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
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
                style: AppTextStyles.bodyMedium,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: _sending
                    ? Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
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
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo sharing coming soon!')));
            },
          ),
          ListTile(
            leading: Icon(Icons.attach_file_rounded, color: AppColors.info),
            title: Text('Share Document', style: AppTextStyles.labelLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document sharing coming soon!')));
            },
          ),
          ListTile(
            leading:
                Icon(Icons.calendar_today_rounded, color: AppColors.emerald),
            title: Text('Schedule Meeting', style: AppTextStyles.labelLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting scheduler coming soon!')));
            },
          ),
          ListTile(
            leading: Icon(Icons.location_on_rounded, color: AppColors.warning),
            title: Text('Share Location', style: AppTextStyles.labelLarge),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location sharing coming soon!')));
            },
          ),
          Divider(color: AppColors.border),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: Text('Delete Chat', style: AppTextStyles.labelLarge.copyWith(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // close bottom sheet
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: const Text('Are you sure you want to delete this chat? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        FirebaseFirestore.instance.collection(AppConstants.colMatches).doc(widget.roomId).delete();
                        Navigator.pop(ctx);
                        Navigator.pop(context); // go back to list
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
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
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMe ? AppColors.goldGradient : null,
          color: isMe ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: isMe
              ? [
                  BoxShadow(
                      color: AppColors.gold.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isMe ? AppColors.textInverse : AppColors.textPrimary,
                )),
            SizedBox(height: 3),
            Text(AppFormatters.formatTime(message.sentAt),
                style: AppTextStyles.caption.copyWith(
                  color: isMe
                      ? AppColors.textInverse.withOpacity(0.7)
                      : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}
