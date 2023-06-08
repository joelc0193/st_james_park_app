import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

import 'package:st_james_park_app/services/firestore_interface.dart';

class MockFirestoreService extends Mock implements FirestoreInterface {
  @override
  Future<void> updateNumber(String path, int number) {
    // TODO: implement updateNumber
    throw UnimplementedError();
  }

  @override
  Stream<DocumentSnapshot> streamData(String path) {
    // TODO: implement streamData
    throw UnimplementedError();
  }

  @override
  Future<void> signUp(String email, String password) {
    // TODO: implement signUp
    throw UnimplementedError();
  }

  @override
  Future<void> logIn(String email, String password) {
    // TODO: implement logIn
    throw UnimplementedError();
  }
}
