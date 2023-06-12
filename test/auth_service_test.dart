import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'mocks.dart';
import 'auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth])
void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);

      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).thenAnswer((_) async => Future.value(MockUserCredential(MockUser())));
    });

    test('signInWithEmailAndPassword signs in the user', () async {
      var _currentUser = MockUser();
      
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).thenAnswer(
          (_) async => Future.value(MockUserCredential(_currentUser)));

      // Action: Call signInWithEmailAndPassword().
      await authService.signInWithEmailAndPassword(
          email: 'test@test.com', password: 'password123');

      // Assert: Check that signInWithEmailAndPassword was called.
      verify(mockAuth.signInWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
    });

    test('createUserWithEmailAndPassword creates a user', () async {
      var _currentUser = MockUser();

      when(mockAuth.createUserWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).thenAnswer(
          (_) async => Future.value(MockUserCredential(_currentUser)));

      // Action: Call createUserWithEmailAndPassword().
      await authService.createUserWithEmailAndPassword(
          email: 'test@test.com', password: 'password123');

      // Assert: Check that createUserWithEmailAndPassword was called.
      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'test@test.com',
        password: 'password123',
      )).called(1);
    });
  });
}
