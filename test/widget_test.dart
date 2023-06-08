// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/main.dart';
import 'package:st_james_park_app/mocks.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create your mock objects
    final MockFirebaseApp mockApp = MockFirebaseApp();
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
