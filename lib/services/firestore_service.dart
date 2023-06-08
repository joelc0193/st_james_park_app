import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FirestoreService({required this.firestore, required this.auth});

  Stream<DocumentSnapshot> getNumber() {
    return firestore.collection('numbers').doc('currentNumber').snapshots();
  }

  Future<void> incrementNumber() async {
    var ref = firestore.collection('numbers').doc('currentNumber');
    return firestore.runTransaction((transaction) async {
      var snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw Exception('Document does not exist!');
      }
      var newNumber = snapshot.data()['currentNumber'] + 1;
      transaction.update(ref, {'currentNumber': newNumber});
    });
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}
