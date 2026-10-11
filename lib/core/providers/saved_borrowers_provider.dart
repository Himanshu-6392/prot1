import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'firebase_providers.dart';

/// Stream of borrower IDs saved by the currently authenticated user
final savedBorrowerIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.watch(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    return Stream.value(<String>{});
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_borrowers')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => doc.id).toSet());
});

/// Stream of all saved borrower records for the currently authenticated user
final savedBorrowersListProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.watch(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    return Stream.value(<Map<String, dynamic>>[]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_borrowers')
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['borrowerId'] = doc.id;
            return data;
          }).toList());
});

/// Helper function to toggle save/unsave state of a borrower in Firestore
Future<bool> toggleSaveBorrower({
  required BuildContext context,
  required WidgetRef ref,
  required String borrowerId,
  required String borrowerName,
  required String borrowerCity,
  required bool isVerified,
  double? loanAmount,
  double? maxInterestRatePerMonth,
  int? tenureMonths,
  String? collateralType,
  double? collateralValue,
  String? requestId,
}) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.read(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to save borrowers'),
        duration: Duration(seconds: 2),
      ),
    );
    return false;
  }

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_borrowers')
      .doc(borrowerId);

  try {
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.bookmark_remove_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Borrower removed from saved',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.textPrimary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    } else {
      await docRef.set({
        'borrowerId': borrowerId,
        'borrowerName': borrowerName,
        'borrowerCity': borrowerCity,
        'isVerified': isVerified,
        'loanAmount': loanAmount ?? 0,
        'maxInterestRatePerMonth': maxInterestRatePerMonth ?? 0,
        'tenureMonths': tenureMonths ?? 0,
        'collateralType': collateralType ?? '',
        'collateralValue': collateralValue ?? 0,
        'requestId': requestId ?? '',
        'savedAt': FieldValue.serverTimestamp(),
        'lenderId': currentUserId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.bookmark_added_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Borrower saved', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return true;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bookmark: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return false;
  }
}
