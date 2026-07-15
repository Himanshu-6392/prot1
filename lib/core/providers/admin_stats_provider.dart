import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_providers.dart';
import '../utils/constants.dart';

class AdminStats {
  final int totalUsers;
  final int activeLenders;
  final int openRequests;
  final int kycPending;

  AdminStats({
    required this.totalUsers,
    required this.activeLenders,
    required this.openRequests,
    required this.kycPending,
  });
}

final adminStatsProvider = StreamProvider<AdminStats>((ref) async* {
  final firestore = ref.watch(firestoreProvider);

  // Create streams for each count
  final usersStream = firestore.collection(AppConstants.colUsers).snapshots();

  await for (final usersSnap in usersStream) {
    int totalUsers = usersSnap.docs.length;
    int activeLenders =
        usersSnap.docs.where((doc) => doc.data()['role'] == 'lender').length;
    int kycPending = usersSnap.docs
        .where((doc) => doc.data()['kycStatus'] == 'pending')
        .length;

    // We get the latest requests count by doing a one-off fetch inside this tick
    // In a production app with huge scale, we would use Cloud Functions for aggregation
    final requestsSnap = await firestore
        .collection(AppConstants.colRequests)
        .where('status', isEqualTo: 'open')
        .get();

    yield AdminStats(
      totalUsers: totalUsers,
      activeLenders: activeLenders,
      openRequests: requestsSnap.docs.length,
      kycPending: kycPending,
    );
  }
});
