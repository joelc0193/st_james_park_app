import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  final MockCollectionReference _collectionReference =
      MockCollectionReference();

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _collectionReference;
  }
}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {
  final MockDocumentReference _documentReference = MockDocumentReference();

  @override
  DocumentReference<Map<String, dynamic>> doc([String? documentPath]) {
    return _documentReference;
  }
}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _controller =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>();
  final MockDocumentSnapshot _documentSnapshot = MockDocumentSnapshot();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return _documentSnapshot;
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    _documentSnapshot.currentNumber = {
      'currentNumber': _documentSnapshot.currentNumber['currentNumber']! + 1,
    };
    print(_documentSnapshot.currentNumber);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) {
    return _controller.stream;
  }

  void addSnapshot(MockDocumentSnapshot snapshot) {
    _controller.add(snapshot);
  }

  void finishStream() {
    _controller.close();
  }
}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  var currentNumber = {'currentNumber': 0};
  @override
  Map<String, dynamic>? data() {
    return currentNumber;
  }

  @override
  bool get exists => true;
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
