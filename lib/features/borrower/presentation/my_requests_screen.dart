import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/interactive_empty_state.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/loan_request_model.dart';
import 'dart:math' as math;

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final userId = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('My Requests', style: AppTextStyles.h3),
        centerTitle: true,
      ),
      body: userId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colRequests)
                  .where('borrowerId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}',
                        style: TextStyle(color: AppColors.error)),
                  );
                }
                if (!snap.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: AppColors.emerald));
                }

                var docs = snap.data!.docs.toList();
                
                // Sort locally to avoid needing a composite index in Firestore
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  DateTime? getSafeTime(Map<String, dynamic> data) {
                    final val = data['createdAt'];
                    if (val is Timestamp) return val.toDate();
                    if (val is String) return DateTime.tryParse(val);
                    return null;
                  }
                  
                  final aTime = getSafeTime(aData) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime = getSafeTime(bData) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  
                  return bTime.compareTo(aTime);
                });

                if (docs.isEmpty) {
                  return const InteractiveEmptyState(
                    title: 'No requests yet',
                    subtitle: 'Post your first loan request to get started.',
                    lottieUrl: 'assets/animations/onboarding_2.json',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final req = LoanRequestModel.fromMap(
                        docs[index].data() as Map<String, dynamic>,
                        docs[index].id);
                    return _MyRequestCard(request: req);
                  },
                );
              },
            ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final LoanRequestModel request;
  const _MyRequestCard({required this.request});

  Color _statusColor(LoanRequestStatus s) => switch (s) {
        LoanRequestStatus.open => AppColors.gold,
        LoanRequestStatus.matched => AppColors.info,
        LoanRequestStatus.accepted => AppColors.emerald,
        LoanRequestStatus.completed => AppColors.success,
        LoanRequestStatus.cancelled => AppColors.error,
        LoanRequestStatus.expired => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.formatINR(request.loanAmount),
                      style: AppTextStyles.h3,
                    ),
                    Text(
                      '${request.tenureMonths} months • ${request.maxInterestRatePerMonth}% / mo',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TagChip(
                label: request.status.name.toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collateral: ${request.collateralType}',
                style: AppTextStyles.labelMedium,
              ),
              Text(
                AppFormatters.formatDate(request.createdAt),
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
