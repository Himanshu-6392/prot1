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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(isLender ? 'My Offers' : 'Match Requests',
            style: AppTextStyles.h3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colMatches)
            .where(isLender ? 'lenderId' : 'borrowerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          final docs = snap.data!.docs;
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
            padding: const EdgeInsets.all(16),
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
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  final bool isLender;
  const _MatchCard({required this.match, required this.isLender});

  Future<void> _accept(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final chatRoomId = '${match.id}_chat';
    await FirebaseFirestore.instance
        .collection(AppConstants.colMatches)
        .doc(match.id)
        .update({
      'status': MatchStatus.accepted.name,
      'chatRoomId': chatRoomId,
      'updatedAt': DateTime.now(),
    });

    // Create a notification for the lender
    await FirebaseFirestore.instance
        .collection('users')
        .doc(match.lenderId)
        .collection('notifications')
        .add({
      'title': 'Offer Accepted! 🎉',
      'body': 'Your offer of ₹${match.offeredAmount} was accepted! Start chatting to finalize the deal.',
      'type': 'match',
      'isRead': false,
      'createdAt': DateTime.now(),
    });

    if (context.mounted) context.push('/chat/$chatRoomId');
  }

  Future<void> _decline(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colMatches)
        .doc(match.id)
        .update({
      'status': MatchStatus.declined.name,
      'updatedAt': DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(match.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: match.status == MatchStatus.pending
                ? AppColors.gold.withOpacity(0.4)
                : AppColors.border,
            width: match.status == MatchStatus.pending ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(match.status.name.toUpperCase(),
                style: AppTextStyles.tag.copyWith(color: statusColor)),
          ),
          Spacer(),
          Text(AppFormatters.formatRelative(match.createdAt),
              style: AppTextStyles.caption),
        ]),
        SizedBox(height: 14),
        Text(
            isLender
                ? 'Borrower: ${match.borrowerId.substring(0, 8)}...'
                : 'Lender: ${match.lenderId.substring(0, 8)}...',
            style: AppTextStyles.labelLarge),
        SizedBox(height: 4),
        Text('Request: ${match.requestId.substring(0, 8)}...',
            style: AppTextStyles.caption),
        if (match.offeredAmount != null &&
            match.offeredInterestRate != null) ...[
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isLender ? 'Your Offer' : 'Lender\'s Offer',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.gold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Amount: ${AppFormatters.formatINR(match.offeredAmount!)}',
                        style: AppTextStyles.labelMedium),
                    Text('Rate: ${match.offeredInterestRate}%/mo',
                        style: AppTextStyles.labelMedium),
                  ],
                ),
                if (match.offerMessage != null &&
                    match.offerMessage!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('"${match.offerMessage}"',
                      style: AppTextStyles.caption
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
        if (match.status == MatchStatus.pending && !isLender) ...[
          SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: AppButton(
                    label: 'Accept',
                    onPressed: () => _accept(context),
                    icon: Icon(Icons.check_rounded, size: 16),
                    color: AppColors.emerald)),
            SizedBox(width: 10),
            Expanded(
                child: AppButton(
                    label: 'Decline',
                    onPressed: () => _decline(context),
                    isOutlined: true,
                    color: AppColors.error)),
          ]),
        ],
        if ((match.status == MatchStatus.accepted) ||
            (isLender && match.status == MatchStatus.pending)) ...[
          SizedBox(height: 14),
          AppButton(
            label: 'Open Chat',
            onPressed: () => context.push('/chat/${match.chatRoomId}'),
            icon: Icon(Icons.chat_bubble_rounded, size: 16),
          ),
        ],
      ]),
    );
  }

  Color _statusColor(MatchStatus s) => switch (s) {
        MatchStatus.pending => AppColors.gold,
        MatchStatus.accepted => AppColors.emerald,
        MatchStatus.declined => AppColors.error,
        MatchStatus.completed => AppColors.success,
      };
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

    setState(() => _isLoading = true);

    try {
      final matchRef =
          FirebaseFirestore.instance.collection(AppConstants.colMatches).doc();
      final chatRoomId = '${matchRef.id}_chat';

      final match = MatchModel(
        id: matchRef.id,
        borrowerId: widget.requestData['borrowerId'],
        lenderId: widget.lenderId,
        requestId: widget.requestId,
        status: MatchStatus.pending,
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
