import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'mocks.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });
    
    test('signOut signs out the user', () async {
      // Setup: Sign in a user.
      await mockAuth.signInAnonymously();

      // Action: Call signOut().
      await authService.signOut();

      // Assert: Check that the user is now signed out.
      var user = mockAuth.currentUser;
      expect(user, isNull);
    });

    test('signInWithEmailAndPassword signs in the user', () async {
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
