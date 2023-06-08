import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_james_park_app/main.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  
  @override
  Future<void> incrementNumber(String path, int number) {
    // TODO: implement incrementNumber
    throw UnimplementedError();
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
}

void main() {
  final mockFirestoreService = MockFirestoreService();

  test('incrementNumber increases the number in Firestore', () async {
    // Arrange
    when(mockFirestoreService.incrementNumber('numbers/currentNumber', 1))
        .thenAnswer((_) async => null);

    // Act
    await mockFirestoreService.incrementNumber('path', 1);

    // Assert
    verify(mockFirestoreService.incrementNumber('path', 1)).called(1);
  });
}
