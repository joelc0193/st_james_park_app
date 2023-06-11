// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/main.dart';
import 'mocks.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_goldens/flutter_goldens.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late FirestoreService firestoreService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    firestoreService =
        FirestoreService(firestore: mockFirestore, auth: mockAuth);
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
    await Future.delayed(Duration(seconds: 1)); // Delay of 1 second
    numberStream.take(5).listen((snapshot) {
      print(
          'Received event with currentNumber = ${(snapshot.data() as Map<String, dynamic>)['currentNumber']}');

      expect(snapshot.data(), isNotNull);
      expect((snapshot.data() as Map<String, dynamic>)['currentNumber'], 42);
    });
  });

  // test('signOut signs out the user', () async {
  //   // Setup: Sign in a user.
  //   await mockAuth.signInAnonymously();

  //   // Action: Call signOut().
  //   await firestoreService.signOut();

  //   // Assert: Check that the user is now signed out.
  //   var user = mockAuth.currentUser;
  //   expect(user, isNull);
  // });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
    final MockFirebaseAuth mockAuth = MockFirebaseAuth();
    // Provide the mock objects using provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseFirestore>(create: (_) => mockFirestore),
          Provider<FirebaseAuth>(create: (_) => mockAuth),
        ],
        child: MyApp(),
      ),
    );

    await tester.pumpAndSettle();
    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
