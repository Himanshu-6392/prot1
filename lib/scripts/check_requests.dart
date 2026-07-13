import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final snap = await FirebaseFirestore.instance.collection('loan_requests').get();
  print('Found ' + snap.docs.length.toString() + ' requests');
  for(var doc in snap.docs){
    print(doc.data()['borrowerName']);
  }
  exit(0);
}
