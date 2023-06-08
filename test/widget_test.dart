import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_james_park_app/main.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  int _number = 0;

  @override
  Future<void> incrementNumber(String path, int number) async {
    _number += number;
  }

  @override
  Stream<DocumentSnapshot> getNumber(String path) {
    // TODO: implement getNumber
    throw UnimplementedError();
  }

  @override
  Future<void> logIn(String email, String password) {
    // TODO: implement logIn
    throw UnimplementedError();
  }

  @override
  Future<void> signUp(String email, String password) {
    // TODO: implement signUp
    throw UnimplementedError();
  }

  @override
  Stream<QuerySnapshot> streamData(String path) {
    // TODO: implement streamData
    throw UnimplementedError();
  }

  int get number => _number;
}

void main() {
  final mockFirestoreService = MockFirestoreService();

  test('incrementNumber increases the number in Firestore', () async {
    // Arrange
    final mockFirestoreService = MockFirestoreService();

    // Act
    await mockFirestoreService.incrementNumber('path', 1);

    // Assert
    expect(mockFirestoreService.number, equals(1));
  });
}
