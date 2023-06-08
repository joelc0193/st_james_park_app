import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService(
      {required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore,
        _auth = auth;

  Stream<DocumentSnapshot> getNumber() {
    return _firestore.collection('numbers').doc('currentNumber').snapshots();
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

  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> logIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }
  Future<void> logOut() async {
    await _auth.signOut();
  }
}
