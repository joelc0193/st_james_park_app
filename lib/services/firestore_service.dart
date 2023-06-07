import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;
        
  Stream<DocumentSnapshot> getNumber() {
    return _firestore.collection('numbers').doc('currentNumber').snapshots();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> incrementNumber() async {
    try {
      await _firestore.collection('numbers').doc('currentNumber').update({
        'currentNumber': FieldValue.increment(1),
      });
      print('Number incremented successfully');
    } catch (e) {
      print('Failed to increment number: $e');
    }
  }
}
