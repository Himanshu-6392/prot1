import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'firebase_providers.dart';

/// Stream of saved lender IDs for the current authenticated user.
final savedLenderIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.watch(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_lenders')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

/// Stream of full saved lender documents for the current authenticated user.
final savedLendersListProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.watch(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_lenders')
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['lenderId'] = doc.id;
            return data;
          }).toList());
});

/// Toggles saving or unsaving a lender for the authenticated user.
Future<bool> toggleSaveLender({
  required BuildContext context,
  required WidgetRef ref,
  required String lenderId,
  required String businessName,
  required String city,
  required bool isVerified,
  double? maxLoanAmount,
  double? minLoanAmount,
  double? interestRatePerMonth,
  int? maxTenureMonths,
  List<String>? acceptedCollateral,
  double? rating,
}) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ??
      ref.read(currentUserProvider).valueOrNull?.uid;

  if (currentUserId == null || currentUserId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save lenders'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('saved_lenders')
      .doc(lenderId);

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
                Text('Lender removed from saved',
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
        'lenderId': lenderId,
        'businessName': businessName,
        'city': city,
        'isVerified': isVerified,
        'maxLoanAmount': maxLoanAmount ?? 0,
        'minLoanAmount': minLoanAmount ?? 0,
        'interestRatePerMonth': interestRatePerMonth ?? 0,
        'maxTenureMonths': maxTenureMonths ?? 0,
        'acceptedCollateral': acceptedCollateral ?? [],
        'rating': rating ?? 0,
        'savedAt': FieldValue.serverTimestamp(),
        'borrowerId': currentUserId,
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
                Text('Lender saved', style: TextStyle(color: Colors.white)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update saved lender: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }
}
