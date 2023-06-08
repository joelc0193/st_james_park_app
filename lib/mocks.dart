import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  final MockCollectionReference _collectionReference = MockCollectionReference();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collectionReference;
  }
}


class MockFirebaseAuth extends Mock implements FirebaseAuth {}
