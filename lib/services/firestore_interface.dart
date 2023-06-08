import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreInterface {
  Stream<DocumentSnapshot> getNumber(String path);
  Future<void> incrementNumber(String path, int number);
}
