import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  final dummies = ['dummy_1', 'dummy_2', 'dummy_3', 'dummy_4'];
  final dummyUsers = [
    'dummy_user_1',
    'dummy_user_2',
    'dummy_user_3',
    'dummy_user_4'
  ];

  for (final id in dummies) {
    try {
      await firestore.collection('lenders').doc(id).delete();
      print('Deleted lender $id');
    } catch (e) {
      print('Error deleting lender $id: $e');
    }
  }

  for (final uid in dummyUsers) {
    try {
      await firestore.collection('users').doc(uid).delete();
      print('Deleted user $uid');
    } catch (e) {
      print('Error deleting user $uid: $e');
    }

    // Also delete any matches sent by or to these dummy users
    try {
      final snapLender = await firestore
          .collection('matches')
          .where('lenderId', isEqualTo: uid)
          .get();
      for (final doc in snapLender.docs) {
        await doc.reference.delete();
        print('Deleted match by dummy lender $uid');
      }

      final snapBorrower = await firestore
          .collection('matches')
          .where('borrowerId', isEqualTo: uid)
          .get();
      for (final doc in snapBorrower.docs) {
        await doc.reference.delete();
        print('Deleted match by dummy borrower $uid');
      }
    } catch (e) {
      print('Error deleting matches for $uid: $e');
    }
  }

  // Also clear the seeder call in dummy_seeder.dart just to be safe
  print('Dummy data cleanup complete.');
}
