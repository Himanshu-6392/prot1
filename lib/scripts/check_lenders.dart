import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final firestore = FirebaseFirestore.instance;
  
  final lenders = await firestore.collection('lenders').get();
  print('Total Lenders: ${lenders.docs.length}');
  
  for (var doc in lenders.docs) {
    final data = doc.data();
    print('Lender: ${doc.id}');
    print('  Business Name: ${data['businessName']}');
    print('  City: ${data['city']}');
    print('  isActive: ${data['isActive']}');
    print('  isVerified: ${data['isVerified']}');
  }
}
