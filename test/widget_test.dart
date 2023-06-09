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

    await tester.pumpAndSettle(); // Add this line

    final numberTextFinder = find.byKey(Key('testKey'));
    expect(numberTextFinder, findsOneWidget);
    final Text textWidget = tester.widget(numberTextFinder);
    print('Data from test Text widget: ${textWidget.data}');

    ((mockFirestore.collection('') as MockCollectionReference).doc()
            as MockDocumentReference)
        .addSnapshot(MockDocumentSnapshot());

    final numberTextFinderPost = find.byKey(Key('testKey'));
    expect(numberTextFinderPost, findsOneWidget);
    final Text textWidgetPost = tester.widget(numberTextFinderPost);
    print('Data from test Text widget: ${textWidgetPost.data}');

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
