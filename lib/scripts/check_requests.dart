import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final snap = await firestore
      .collection('requests')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .get();

  print("Found ${snap.docs.length} requests:");
  for (var doc in snap.docs) {
    print(
        "${doc.id} - ${doc.data()['borrowerName']} - ${doc.data()['loanAmount']} - status: ${doc.data()['status']} - createdAt: ${doc.data()['createdAt']}");
  }
}
