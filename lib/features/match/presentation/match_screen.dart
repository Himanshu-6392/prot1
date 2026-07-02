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

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('Match Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colMatches)
            .where('borrowerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.gold));
          final docs = snap.data!.docs;
          if (docs.isEmpty) return EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No matches yet',
            subtitle: 'When lenders respond to your requests, they\'ll appear here.',
          );

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final match = MatchModel.fromMap(docs[i].data() as Map<String, dynamic>, docs[i].id);
              return _MatchCard(match: match, isLender: false)
                  .animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.1, end: 0);
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
    await FirebaseFirestore.instance.collection(AppConstants.colMatches).doc(match.id).update({
      'status':     MatchStatus.accepted.name,
      'chatRoomId': chatRoomId,
      'updatedAt':  DateTime.now(),
    });
    if (context.mounted) context.push('/chat/$chatRoomId');
  }

  Future<void> _decline(BuildContext context) async {
    await FirebaseFirestore.instance.collection(AppConstants.colMatches).doc(match.id).update({
      'status':    MatchStatus.declined.name,
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
        border: Border.all(color: match.status == MatchStatus.pending ? AppColors.gold.withOpacity(0.4) : AppColors.border,
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
          Text(AppFormatters.formatRelative(match.createdAt), style: AppTextStyles.caption),
        ]),
        SizedBox(height: 14),
        Text('Lender: ${match.lenderId.substring(0, 8)}...',
            style: AppTextStyles.labelLarge),
        SizedBox(height: 4),
        Text('Request: ${match.requestId.substring(0, 8)}...',
            style: AppTextStyles.caption),

        if (match.status == MatchStatus.pending && !isLender) ...[
          SizedBox(height: 16),
          Row(children: [
            Expanded(child: AppButton(label: 'Accept', onPressed: () => _accept(context),
                icon: Icon(Icons.check_rounded, size: 16), color: AppColors.emerald)),
            SizedBox(width: 10),
            Expanded(child: AppButton(label: 'Decline', onPressed: () => _decline(context),
                isOutlined: true, color: AppColors.error)),
          ]),
        ],

        if (match.status == MatchStatus.accepted) ...[
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
    MatchStatus.pending   => AppColors.gold,
    MatchStatus.accepted  => AppColors.emerald,
    MatchStatus.declined  => AppColors.error,
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
      appBar: AppBar(title: Text('Loan Request Detail')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection(AppConstants.colRequests).doc(requestId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.gold));
          if (!snap.data!.exists) return Center(child: Text('Request not found', style: AppTextStyles.h3));
          final data = snap.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Column(children: [
                  Text(AppFormatters.formatINR((data['loanAmount'] ?? 0).toDouble()),
                      style: AppTextStyles.amountLarge),
                  SizedBox(height: 4),
                  Text('Loan Amount', style: AppTextStyles.caption),
                  SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _DetailStat('Collateral', data['collateralType'] ?? '—'),
                    _DetailStat('Max Rate', '${data['maxInterestRatePerMonth'] ?? '-'}%/mo'),
                    _DetailStat('Tenure', AppFormatters.formatTenure(data['tenureMonths'] ?? 1)),
                  ]),
                ]),
              ).animate().fadeIn(),

              SizedBox(height: 24),
              Text('Borrower', style: AppTextStyles.h3),
              SizedBox(height: 12),
              Row(children: [
                Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text((data['borrowerName'] ?? 'B')[0].toUpperCase(),
                      style: AppTextStyles.labelLarge))),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['borrowerName'] ?? '', style: AppTextStyles.labelLarge),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                    Text(data['borrowerCity'] ?? '', style: AppTextStyles.caption),
                  ]),
                ]),
                Spacer(),
                if (data['isVerified'] == true) VerifiedBadge(),
              ]),

              SizedBox(height: 20),
              Text('Description', style: AppTextStyles.h3),
              SizedBox(height: 8),
              Text(data['description'] ?? '', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),

              SizedBox(height: 20),
              Text('Collateral Details', style: AppTextStyles.h3),
              SizedBox(height: 12),
              _DetailRow2('Type',  data['collateralType'] ?? '—'),
              _DetailRow2('Value', AppFormatters.formatINR((data['collateralValue'] ?? 0).toDouble())),

              SizedBox(height: 28),
              AppButton(
                label: 'Send Offer to Borrower',
                onPressed: () {},
                icon: Icon(Icons.send_rounded, size: 18),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  const _DetailStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.labelLarge.copyWith(color: AppColors.gold)),
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
      Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      Spacer(),
      Text(value, style: AppTextStyles.labelMedium),
    ]),
  );
}
