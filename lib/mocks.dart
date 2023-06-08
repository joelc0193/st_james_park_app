import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {
  final MockDocumentReference _documentReference = MockDocumentReference();

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    return _documentReference;
  }
}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  final MockCollectionReference _collectionReference = MockCollectionReference();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collectionReference;
  }
}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({bool includeMetadataChanges = false}) {
    return Stream.value(MockDocumentSnapshot());
  }
}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? data() {
    return {'number': 1};  // return the mock data you want
  }
}


class MockFirebaseAuth extends Mock implements FirebaseAuth {}
