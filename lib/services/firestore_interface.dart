import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreInterface {
  Future<void> updateNumber(String path, int number);
  Stream<DocumentSnapshot> streamData(String path);
  Future<void> signUp(String email, String password);
  Future<void> logIn(String email, String password);
}
