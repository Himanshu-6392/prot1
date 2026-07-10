import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.h3),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () async {
                // Mark all unread notifications as read
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .get();

                final batch = FirebaseFirestore.instance.batch();
                for (var doc in query.docs) {
                  batch.update(doc.reference, {'isRead': true});
                }
                await batch.commit();
              },
              child: Text('Mark all read',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.gold)),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading notifications',
                          style: AppTextStyles.bodyMedium));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle:
                        'We\'ll notify you of matches, messages, and updates.',
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final notifMap = docs[i].data() as Map<String, dynamic>;
                    final notif =
                        NotificationModel.fromMap(notifMap, docs[i].id);

                    return _NotifTile(notif: notif)
                        .animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn()
                        .slideX(begin: 0.05, end: 0);
                  },
                );
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          notif.isRead ? Colors.transparent : AppColors.gold.withOpacity(0.04),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: notif.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(notif.icon, color: notif.color, size: 22),
        ),
        title: Row(children: [
          Expanded(child: Text(notif.title, style: AppTextStyles.labelLarge)),
          if (!notif.isRead)
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(notif.body,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 2),
            const SizedBox(height: 4),
            Text(AppFormatters.formatRelative(notif.createdAt),
                style: AppTextStyles.caption),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
