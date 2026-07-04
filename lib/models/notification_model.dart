import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'match', 'message', 'kyc', 'review', 'system'
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  /// Helper to get an icon based on notification type
  IconData get icon {
    switch (type) {
      case 'match': return Icons.handshake_rounded;
      case 'message': return Icons.chat_bubble_rounded;
      case 'kyc': return Icons.verified_rounded;
      case 'review': return Icons.star_rounded;
      default: return Icons.info_rounded;
    }
  }

  /// Helper to get a color based on notification type
  Color get color {
    switch (type) {
      case 'match': return AppColors.gold;
      case 'message': return AppColors.info;
      case 'kyc': return AppColors.emerald;
      case 'review': return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }
}
