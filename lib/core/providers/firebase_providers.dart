import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';

// ─── Firebase Instances ───────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final storageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

final rtdbProvider = Provider<FirebaseDatabase>(
  (ref) => FirebaseDatabase.instance,
);

// ─── Auth State ───────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ─── Current User Model ───────────────────────
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) {
        if (!snap.exists) return null;
        return UserModel.fromMap(snap.data()!, snap.id);
      });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// ─── Fetch Specific User ───────────────────────
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final snap = await ref.watch(firestoreProvider).collection('users').doc(uid).get();
  if (!snap.exists) return null;
  return UserModel.fromMap(snap.data()!, snap.id);
});
