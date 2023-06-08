import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_james_park_app/home_page.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class TestableMyApp extends StatelessWidget {
  final FirebaseInitializer initializer;

  TestableMyApp({required this.initializer});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: initializer.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const MyHomePage();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create instances of your mock classes
    MockFirestore mockFirestore = MockFirestore();
    MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();

    // Use the mock instances in your tests
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(
        firestore: mockFirestore,
        auth: mockFirebaseAuth,
      ),
    ));

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
