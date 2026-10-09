import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AdminReportCenterScreen extends ConsumerStatefulWidget {
  const AdminReportCenterScreen({super.key});

  @override
  ConsumerState<AdminReportCenterScreen> createState() => _AdminReportCenterScreenState();
}

class _AdminReportCenterScreenState extends ConsumerState<AdminReportCenterScreen> {
  String _filter = 'open'; // open, resolved

  void _resolveReport(String docId, String currentNotes) {
    final noteCtrl = TextEditingController(text: currentNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve Report', style: AppTextStyles.h3),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(labelText: 'Admin Notes / Action Taken'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('reports').doc(docId).update({
                'status': 'resolved',
                'adminNotes': noteCtrl.text.trim(),
                'resolvedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Mark Resolved'),
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
        title: Text('Report Center', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _filter = 'open'),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _filter == 'open' ? AppColors.error : Colors.transparent, width: 2)),
                    ),
                    child: Text('Open Reports', style: AppTextStyles.labelLarge.copyWith(color: _filter == 'open' ? AppColors.error : AppColors.textMuted)),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _filter = 'resolved'),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _filter == 'resolved' ? AppColors.emerald : Colors.transparent, width: 2)),
                    ),
                    child: Text('Resolved', style: AppTextStyles.labelLarge.copyWith(color: _filter == 'resolved' ? AppColors.emerald : AppColors.textMuted)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: _filter)
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

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No $_filter reports', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final reportType = data['reportType'] as String? ?? 'General';
              final reason = data['reason'] as String? ?? 'No reason provided';
              final reportedUserId = data['reportedUserId'] as String? ?? '';
              final reportedByUserId = data['reportedByUserId'] as String? ?? '';
              final adminNotes = data['adminNotes'] as String? ?? '';
              final ts = data['createdAt'] as Timestamp?;
              final timeStr = ts != null ? DateFormat('dd MMM yyyy, h:mm a').format(ts.toDate()) : 'Now';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(reportType.toUpperCase(), style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Text(timeStr, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Reason: $reason', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reported User: $reportedUserId', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontFamily: 'monospace')),
                            const SizedBox(height: 4),
                            Text('Reported By: $reportedByUserId', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      if (adminNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Admin Notes:', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary)),
                        Text(adminNotes, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                      if (_filter == 'open') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _resolveReport(docs[index].id, adminNotes),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.emerald,
                                side: BorderSide(color: AppColors.emerald),
                              ),
                              child: const Text('Resolve'),
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
}
