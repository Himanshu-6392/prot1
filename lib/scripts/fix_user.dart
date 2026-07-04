import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> fixCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("No user is currently logged in.");
    return;
  }
  
  print("Current User UID: ${user.uid}");
  print("Current User Email: ${user.email}");
  
  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final doc = await docRef.get();
  
  if (!doc.exists) {
    print("Firestore document doesn't exist for this UID. Creating one now...");
    await docRef.set({
      'name': 'Himanshu Kumar', // A default name since we don't know it
      'email': user.email ?? 'himanshu@example.com',
      'phone': '',
      'role': 'borrower',
      'city': 'Delhi',
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print("Created Firestore document for user!");
  } else {
    print("Firestore document exists. Data: ${doc.data()}");
    if (doc.data()?['name'] == null || doc.data()?['name'] == '') {
      await docRef.update({'name': 'Himanshu Kumar', 'city': 'Delhi'});
      print("Updated empty name to Himanshu Kumar");
    }
  }
}
