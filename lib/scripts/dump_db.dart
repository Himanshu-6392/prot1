import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:peerlend/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  print('Fetching Lenders...');
  final lenders = await firestore.collection('lenders').get();
  for (var doc in lenders.docs) {
    print('Lender: ${doc.id} => ${doc.data()}');
  }

  print('\nFetching Requests...');
  final requests = await firestore.collection('loan_requests').get();
  for (var doc in requests.docs) {
    print('Request: ${doc.id} => ${doc.data()}');
  }

  print('\nDone!');
}
