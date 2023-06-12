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
  var currentNumber = {'currentNumber': 0};

  MockDocumentReference() {
    _controller.add(MockDocumentSnapshot(currentNumber));
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    return MockDocumentSnapshot(currentNumber);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    currentNumber = {
      'currentNumber': data['currentNumber'] as int,
    };
    _controller.add(MockDocumentSnapshot(currentNumber));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) {
    return _controller.stream;
  }

  void finishStream() {
    _controller.close();
  }
}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> snapshotData;

  MockDocumentSnapshot(this.snapshotData);

  @override
  Map<String, dynamic>? data() {
    return snapshotData;
  }

  @override
  bool get exists => true;
}

// class MockFirebaseAuth extends Mock implements FirebaseAuth {}


class MockUserCredential extends Mock implements UserCredential {
  User? _user;

  MockUserCredential(this._user);

  @override
  User get user => _user!;
}

class MockUser extends Mock implements User {}
