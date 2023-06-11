import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

import 'mocks.dart';

void main() {
  group('FirestoreService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late FirestoreService firestoreService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      firestoreService =
          FirestoreService(firestore: mockFirestore, auth: mockAuth);
    });

    test('incrementNumber increases the number in Firestore', () async {
      await firestoreService.incrementNumber();

      var snapshot =
          await mockFirestore.collection('numbers').doc('currentNumber').get();
      var data = snapshot.data();
      expect(data?['currentNumber'], 1);
    });

    test('getNumber returns the current number from Firestore', () async {
      // Setup: Add a number to Firestore.
      await mockFirestore
          .collection('numbers')
          .doc('currentNumber')
          .update({'currentNumber': 42});

      // Action: Call getNumber().
      var numberStream = firestoreService.getNumber();

      // Assert: Check that the number returned by getNumber() is the number we added to Firestore.
      var secondEvent = await numberStream.elementAt(1);
      var data = secondEvent.data();
      var currentNumber = (data! as Map<String, int>)['currentNumber'];
      expect(currentNumber, 42);
    });

    test('signOut signs out the user', () async {
      // Setup: Sign in a user.
      await mockAuth.signInAnonymously();

      // Action: Call signOut().
      await firestoreService.signOut();

      // Assert: Check that the user is now signed out.
      var user = mockAuth.currentUser;
      expect(user, isNull);
    });
  });
}
