import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore;

  FirestoreService({required this.firestore});

  Stream<DocumentSnapshot> getNumber() {
    return firestore.collection('numbers').doc('currentNumber').snapshots();
  }

  Future<void> incrementNumber() async {
    try {
      var snapshot =
          await firestore.collection('numbers').doc('currentNumber').get();
          print(snapshot);
      if (snapshot.exists) {
        var currentNumber = snapshot.data()?['currentNumber'];
        if (currentNumber != null) {
          await firestore.collection('numbers').doc('currentNumber').update({
            'currentNumber': currentNumber + 1,
          });
          print('Number incremented successfully');
        } else {
          print('currentNumber field is null');
        }
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Failed to increment number: $e');
    }
  }
}
