import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

class AdminSecurityLogScreen extends ConsumerStatefulWidget {
  const AdminSecurityLogScreen({super.key});

  @override
  ConsumerState<AdminSecurityLogScreen> createState() => _AdminSecurityLogScreenState();
}

class _AdminSecurityLogScreenState extends ConsumerState<AdminSecurityLogScreen> {
  String _filter = 'All'; // All, Critical, Warning, Info

  Color _getSeverityColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      case 'info':
      default:
        return AppColors.info;
    }
  }

  IconData _getSeverityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Icons.gpp_bad_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Security Log', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: AppColors.textPrimary),
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (ctx) => ['All', 'Critical', 'Warning', 'Info']
                .map((e) => PopupMenuItem(
                      value: e,
                      child: Text(e, style: TextStyle(color: _filter == e ? AppColors.gold : AppColors.textPrimary)),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('security_log')
            .orderBy('timestamp', descending: true)
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
          if (_filter != 'All') {
            docs = docs.where((d) => (d.data() as Map)['level'].toString().toLowerCase() == _filter.toLowerCase()).toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No security events found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final level = data['level'] as String? ?? 'info';
              final event = data['event'] as String? ?? 'Unknown Event';
              final userId = data['userId'] as String? ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final timeStr = ts != null ? DateFormat('dd MMM yyyy, h:mm a').format(ts.toDate()) : 'Now';
              
              final color = _getSeverityColor(level);
              final icon = _getSeverityIcon(level);

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(event, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    level.toUpperCase(),
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (userId.isNotEmpty) ...[
                              Text('User ID: $userId', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontFamily: 'monospace')),
                              const SizedBox(height: 4),
                            ],
                            Text(timeStr, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
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
