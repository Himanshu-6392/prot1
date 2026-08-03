import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Event types for colour-coding and icons in the admin activity log.
enum ActivityType {
  login,
  signup,
  logout,
  loanRequest,
  loanUpdate,
  lenderJoin,
  kycSubmit,
  kycApprove,
  kycReject,
  collateral,
  offer,
  match,
  adminAction,
  maintenance,
  announcement,
  profileUpdate,
  roleChange,
  subscription,
  chat,
}

/// Call [ActivityLogService.log] from anywhere in the app to record an event.
class ActivityLogService {
  ActivityLogService._();

  static final _col = FirebaseFirestore.instance.collection('admin_activity_log');

  /// Write an activity entry to Firestore.
  ///
  /// [type]    — one of [ActivityType] (determines icon / colour in admin UI)
  /// [title]   — short headline, e.g. "New Loan Request"
  /// [detail]  — optional extra context shown as subtitle
  /// [userId]  — UID of the user who triggered the action (defaults to current user)
  /// [meta]    — extra key-value pairs stored for future drill-down
  static Future<void> log({
    required ActivityType type,
    required String title,
    String? detail,
    String? userId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      await _col.add({
        'type': type.name,
        'title': title,
        'detail': detail ?? '',
        'userId': uid ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        ...?meta,
      });
    } catch (_) {
      // Never crash the app just because logging failed
    }
  }
}
