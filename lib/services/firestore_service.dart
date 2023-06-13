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
    try {
      await firestore.collection('numbers').doc('adminNumbers').set({
        ...numbers,
        'Last Update': getServerTimestamp(),
      });
      print('Numbers updated successfully');
    } catch (e) {
      print('Failed to update numbers: $e');
    }
  }
}
