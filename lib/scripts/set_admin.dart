import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  for (var doc in snapshot.docs) {
    final email = (doc.data()['email'] as String?)?.toLowerCase() ?? '';
    if (email.contains('admin104')) {
      print('Found admin104 user! Updating role to admin...');
      await doc.reference.update({
        'role': 'admin',
        'isPremium': true,
      });
      print('Updated successfully!');
    }
  }
  print('Done!');
}
