import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getNumber() {
    return _firestore.collection('numbers').doc('currentNumber').snapshots();
  }

  Future<void> incrementNumber() async {
    DocumentReference numberRef =
        _firestore.collection('numbers').doc('currentNumber');
    DocumentSnapshot numberSnap = await numberRef.get();

    if (numberSnap.exists) {
      int currentNumber = (numberSnap.data() as dynamic)['number'];
      await numberRef.update({'number': currentNumber + 1});
    } else {
      await numberRef.set({'number': 1});
    }
  }
}
