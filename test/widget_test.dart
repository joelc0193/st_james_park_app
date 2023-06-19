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

      when(mockDocumentSnapshot1.exists).thenAnswer((_) => true);
      when(mockDocumentSnapshot1.data())
          .thenAnswer((_) => {'currentNumber': 0});
      when(mockDocumentSnapshot2.exists).thenAnswer((_) => true);

      when(mockDocumentSnapshot2.data())
          .thenAnswer((_) => {'currentNumber': 1});
      when(mockFirestoreService.getAdminNumbers())
          .thenAnswer((_) => controller1.stream);
      when(mockAuth.currentUser).thenAnswer((_) => mockUser);

      // Provide the mock objects using provider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseFirestore>(create: (_) => mockFirestore),
            Provider<FirebaseAuth>(create: (_) => mockAuth),
            Provider<FirestoreService>(create: (_) => mockFirestoreService),
          ],
          child: const MaterialApp(
            // Add MaterialApp here
            home: AdminPage(),
          ),
        ),
      );

      // Simulate entering numbers into the text fields
      await tester.enterText(find.byKey(const Key('Basketball Courts')), '1');
      await tester.enterText(find.byKey(const Key('Tennis Courts')), '2');
      await tester.enterText(find.byKey(const Key('Soccer Field')), '3');
      await tester.enterText(find.byKey(const Key('Playground')), '4');
      await tester.enterText(find.byKey(const Key('Handball Courts')), '5');
      await tester.enterText(find.byKey(const Key('Other')), '6');

      // Simulate tapping the submit button
      await tester.tap(find.byKey(const Key('Submit')));
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

  group('MainNavigationController', () {
    testWidgets('displays the updated numbers', (WidgetTester tester) async {
      // Arrange:
      TestWidgetsFlutterBinding.ensureInitialized();

      final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
      final MockFirebaseAuth mockAuth = MockFirebaseAuth();
      final MockFirestoreService mockFirestoreService = MockFirestoreService();
      final MockDocumentSnapshot mockDocumentSnapshot1 = MockDocumentSnapshot();
      final data = {
        'Basketball Courts': 1,
        'Tennis Courts': 2,
        'Soccer Field': 3,
        'Playground': 4,
        'Handball Courts': 5,
        'Other': 6,
        'Updated': Timestamp.now(),
      };

      var controller = StreamController<DocumentSnapshot>();
      controller.add(mockDocumentSnapshot1);

      when(mockDocumentSnapshot1.exists).thenAnswer((_) => true);
      when(mockDocumentSnapshot1.data()).thenAnswer((_) => data);
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
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      List<String> orderedKeys = [
        'Basketball Courts',
        'Tennis Courts',
        'Soccer Field',
        'Playground',
        'Handball Courts',
        'Other'
      ];

      for (var key in orderedKeys) {
        // Scroll until the item with Key(key) is visible.
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.pumpAndSettle();

        // Now the item should be findable.
        final finder = find.byKey(Key(key));
        expect(finder, findsOneWidget);
        final Text textWidget = tester.widget<Text>(finder);
        final data = mockDocumentSnapshot1.data() as Map<String, dynamic>;
        expect(textWidget.data, (data[key] as int).toString());
      }

      final finder7 = find.byKey(const Key('Total'));
      expect(finder7, findsOneWidget);
      final Text textWidget7 = tester.widget(finder7);
      expect(textWidget7.data, '21');
    });
  });
}
