import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_interface.dart';

class FirestoreService implements FirestoreInterface {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService(
      {required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  @override
  Stream<DocumentSnapshot> getNumber(String path) {
    return _firestore.doc(path).snapshots();
  }

  @override
  Future<void> incrementNumber(String path, int number) async {
    try {
      await _firestore.doc(path).update({
        'currentNumber': FieldValue.increment(number),
      });
      print('Number incremented successfully');
    } catch (e) {
      print('Failed to increment number: $e');
    }
  }
}
