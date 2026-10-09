import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────
// Platform Settings Provider
// Real-time stream of admin_settings/platform document.
// Any widget/router that watches this will react immediately
// when the admin toggles maintenance mode or sends announcements.
// ─────────────────────────────────────────────────────────────

final platformSettingsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('admin_settings')
      .doc('platform')
      .snapshots()
      .map((snap) => snap.data() ?? {});
});

// Convenience bool — true when platform is in maintenance
final maintenanceModeProvider = Provider<bool>((ref) {
  final settings = ref.watch(platformSettingsProvider);
  return settings.when(
    data: (data) => data['maintenanceMode'] == true,
    loading: () => false,
    error: (_, __) => false,
  );
});
