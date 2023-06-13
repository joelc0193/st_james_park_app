// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:st_james_park_app/admin_page.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/main.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

import 'widget_test.mocks.dart';

@GenerateMocks(
    [FirebaseFirestore, FirebaseAuth, FirestoreService, DocumentSnapshot, User])
void main() {
  group('AdminPage', () {
    testWidgets('updates numbers in Firestore when submitted',
        (WidgetTester tester) async {
      // Arrange:
      TestWidgetsFlutterBinding.ensureInitialized();

      final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
      final MockFirebaseAuth mockAuth = MockFirebaseAuth();
      final MockFirestoreService mockFirestoreService = MockFirestoreService();
      final MockDocumentSnapshot mockDocumentSnapshot1 = MockDocumentSnapshot();
      final MockDocumentSnapshot mockDocumentSnapshot2 = MockDocumentSnapshot();
      final MockUser mockUser = MockUser();

      var controller = StreamController<DocumentSnapshot>();
      controller.add(mockDocumentSnapshot1);

      var controller1 = StreamController<DocumentSnapshot>();

      when(mockFirestoreService.getNumber())
          .thenAnswer((_) => controller.stream);
      when(mockDocumentSnapshot1.exists).thenAnswer((_) => true);
      when(mockDocumentSnapshot1.data())
          .thenAnswer((_) => {'currentNumber': 0});
      when(mockDocumentSnapshot2.exists).thenAnswer((_) => true);

      when(mockDocumentSnapshot2.data())
          .thenAnswer((_) => {'currentNumber': 1});
      when(mockFirestoreService.getAdminNumbers())
          .thenAnswer((_) => controller1.stream);
      when(mockFirestoreService.getNumber())
          .thenAnswer((_) => controller.stream);
      when(mockFirestoreService.incrementNumber()).thenAnswer((_) async {
        controller.add(mockDocumentSnapshot2);
        return Future.value();
      });
      when(mockAuth.currentUser).thenAnswer((_) => mockUser);

      // Provide the mock objects using provider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseFirestore>(create: (_) => mockFirestore),
            Provider<FirebaseAuth>(create: (_) => mockAuth),
            Provider<FirestoreService>(create: (_) => mockFirestoreService),
          ],
          child: MaterialApp(
            // Add MaterialApp here
            home: AdminPage(),
          ),
        ),
      );

      // Simulate entering numbers into the text fields
      await tester.enterText(find.byKey(Key('Basketball Courts')), '1');
      await tester.enterText(find.byKey(Key('Tennis Courts')), '2');
      await tester.enterText(find.byKey(Key('Soccer Field')), '3');
      await tester.enterText(find.byKey(Key('Playground')), '4');
      await tester.enterText(find.byKey(Key('Handball Courts')), '5');
      await tester.enterText(find.byKey(Key('Other')), '6');

      // Simulate tapping the submit button
      await tester.tap(find.byKey(Key('Submit')));
      await tester.pumpAndSettle();

      // Verify that the updateAdminNumbers method was called with the correct arguments
      verify(mockFirestoreService.updateAdminNumbers({
        'Basketball Courts': 1,
        'Tennis Courts': 2,
        'Soccer Field': 3,
        'Playground': 4,
        'Handball Courts': 5,
        'Other': 6
      })).called(1);
    });
  });

  group('MyHomePage', () {
    testWidgets('displays the updated numbers', (WidgetTester tester) async {
      // Arrange:
      TestWidgetsFlutterBinding.ensureInitialized();

      final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
      final MockFirebaseAuth mockAuth = MockFirebaseAuth();
      final MockFirestoreService mockFirestoreService = MockFirestoreService();
      final MockDocumentSnapshot mockDocumentSnapshot1 = MockDocumentSnapshot();

      var controller = StreamController<DocumentSnapshot>();
      controller.add(mockDocumentSnapshot1);

      when(mockDocumentSnapshot1.exists).thenAnswer((_) => true);
      when(mockDocumentSnapshot1.data()).thenAnswer((_) => {
            'Basketball Courts': 1,
            'Tennis Courts': 2,
            'Soccer Field': 3,
            'Playground': 4,
            'Handball Courts': 5,
            'Other': 6,
            'Last Update': Timestamp.now(),
          });
      when(mockFirestoreService.getAdminNumbers())
          .thenAnswer((_) => controller.stream);

      // Provide the mock objects using provider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseFirestore>(create: (_) => mockFirestore),
            Provider<FirebaseAuth>(create: (_) => mockAuth),
            Provider<FirestoreService>(create: (_) => mockFirestoreService),
          ],
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      final finder1 = find.byKey(Key('Basketball Courts'));
      expect(finder1, findsOneWidget);
      final Text textWidget1 = tester.widget(finder1);
      expect(textWidget1.data, '1');

      final finder2 = find.byKey(Key('Tennis Courts'));
      expect(finder2, findsOneWidget);
      final Text textWidget2 = tester.widget(finder2);
      expect(textWidget2.data, '2');

      final finder3 = find.byKey(Key('Soccer Field'));
      expect(finder3, findsOneWidget);
      final Text textWidget3 = tester.widget(finder3);
      expect(textWidget3.data, '3');

      final finder4 = find.byKey(Key('Playground'));
      expect(finder4, findsOneWidget);
      final Text textWidget4 = tester.widget(finder4);
      expect(textWidget4.data, '4');

      final finder5 = find.byKey(Key('Handball Courts'));
      expect(finder5, findsOneWidget);
      final Text textWidget5 = tester.widget(finder5);
      expect(textWidget5.data, '5');

      final finder6 = find.byKey(Key('Other'));
      expect(finder6, findsOneWidget);
      final Text textWidget6 = tester.widget(finder6);
      expect(textWidget6.data, '6');

      final finder7 = find.byKey(Key('Total'));
      expect(finder7, findsOneWidget);
      final Text textWidget7 = tester.widget(finder7);
      expect(textWidget7.data, '21');

    });
  });
}
