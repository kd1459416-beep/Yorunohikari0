import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _auth.currentUser?.uid;
    return uid == null ? null : _db.collection('users').doc(uid);
  }

  Future<Map<String, dynamic>> load() async =>
      (await _doc?.get())?.data() ?? const {};

  Future<void> update(Map<String, dynamic> data) async {
    await _doc?.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
