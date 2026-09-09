import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  String _filter = 'All'; // All, Flagged, Disputes

  void _resolveReview(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve Review', style: AppTextStyles.h3),
        content: const Text('Mark this review/dispute as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reviews').doc(docId).update({
                'isFlagged': false,
                'isDisputed': false,
                'resolvedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _deleteReview(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Review', style: AppTextStyles.h3.copyWith(color: AppColors.error)),
        content: const Text('Are you sure you want to permanently delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reviews').doc(docId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Reviews & Disputes', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _buildTab('All', AppColors.info),
              _buildTab('Flagged', AppColors.warning),
              _buildTab('Disputes', AppColors.error),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.error)));
          }

          var docs = snapshot.data?.docs ?? [];
          if (_filter == 'Flagged') {
            docs = docs.where((d) => (d.data() as Map)['isFlagged'] == true).toList();
          } else if (_filter == 'Disputes') {
            docs = docs.where((d) => (d.data() as Map)['isDisputed'] == true).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_outline_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No $_filter reviews', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rating = data['rating'] as double? ?? 0.0;
              final comment = data['comment'] as String? ?? 'No comment';
              final reviewerId = data['reviewerId'] as String? ?? '';
              final revieweeId = data['revieweeId'] as String? ?? '';
              final isFlagged = data['isFlagged'] == true;
              final isDisputed = data['isDisputed'] == true;
              final ts = data['createdAt'] as Timestamp?;
              final timeStr = ts != null ? DateFormat('dd MMM yyyy').format(ts.toDate()) : 'Now';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDisputed ? AppColors.error : isFlagged ? AppColors.warning : AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                            ],
                          ),
                          Text(timeStr, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(comment, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reviewer: $reviewerId', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontFamily: 'monospace')),
                            const SizedBox(height: 4),
                            Text('Reviewee: $revieweeId', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      if (isFlagged || isDisputed) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (isDisputed)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text('DISPUTED', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            if (isFlagged)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text('FLAGGED', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.check_circle_outline, color: AppColors.emerald),
                              onPressed: () => _resolveReview(docs[index].id),
                              tooltip: 'Resolve',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => _deleteReview(docs[index].id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, Color highlightColor) {
    final isSelected = _filter == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = title),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? highlightColor : Colors.transparent, width: 2)),
          ),
          child: Text(title, style: AppTextStyles.labelLarge.copyWith(color: isSelected ? highlightColor : AppColors.textMuted)),
        ),
      ),
    );
  }
}
