import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore;

  FirestoreService({required this.firestore});

  FieldValue getServerTimestamp() {
    return FieldValue.serverTimestamp();
  }

  Stream<DocumentSnapshot> getAdminNumbers() {
    return firestore.collection('numbers').doc('adminNumbers').snapshots();
  }

  Future<void> updateAdminNumbers(Map<String, int> numbers) async {
    await firestore.collection('numbers').doc('adminNumbers').set({
      ...numbers,
      'Updated': getServerTimestamp(),
    });
  }
}
