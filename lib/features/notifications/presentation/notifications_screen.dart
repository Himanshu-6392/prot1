import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/formatters.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _Notif(
        icon: Icons.handshake_rounded, color: AppColors.gold,
        title: 'New Match!', body: 'Prabhat Finance responded to your request of ₹25,000',
        time: DateTime.now().subtract(const Duration(minutes: 5)), isRead: false,
      ),
      _Notif(
        icon: Icons.chat_bubble_rounded, color: AppColors.info,
        title: 'New Message', body: 'You have a new message in your active deal chat.',
        time: DateTime.now().subtract(const Duration(hours: 2)), isRead: false,
      ),
      _Notif(
        icon: Icons.verified_rounded, color: AppColors.emerald,
        title: 'KYC Verified!', body: 'Your KYC documents have been verified. You are now a trusted borrower.',
        time: DateTime.now().subtract(const Duration(hours: 6)), isRead: true,
      ),
      _Notif(
        icon: Icons.star_rounded, color: AppColors.gold,
        title: 'New Review', body: 'A borrower left you a 5★ review. Check it out!',
        time: DateTime.now().subtract(const Duration(days: 1)), isRead: true,
      ),
      _Notif(
        icon: Icons.info_rounded, color: AppColors.textMuted,
        title: 'Request Expiring', body: 'Your loan request for ₹50,000 expires in 3 days.',
        time: DateTime.now().subtract(const Duration(days: 2)), isRead: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'We\'ll notify you of matches, messages, and updates.',
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) => _NotifTile(notif: notifications[i])
                  .animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0),
            ),
    );
  }
}

class _Notif {
  final IconData icon;
  final Color color;
  final String title, body;
  final DateTime time;
  final bool isRead;
  const _Notif({required this.icon, required this.color, required this.title,
    required this.body, required this.time, required this.isRead});
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.isRead ? Colors.transparent : AppColors.gold.withOpacity(0.04),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:        notif.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(notif.icon, color: notif.color, size: 22),
        ),
        title: Row(children: [
          Expanded(child: Text(notif.title, style: AppTextStyles.labelLarge)),
          if (!notif.isRead) Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 3),
            Text(notif.body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 2),
            SizedBox(height: 4),
            Text(AppFormatters.formatRelative(notif.time), style: AppTextStyles.caption),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
