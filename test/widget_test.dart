import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';

import 'package:st_james_park_app/main.dart';

class FirebaseInitializer {
  Future<FirebaseApp> initializeApp() {
    return Firebase.initializeApp();
  }
}

class MockFirebaseInitializer extends Mock implements FirebaseInitializer {}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MockFirebaseInitializer mockInitializer = MockFirebaseInitializer();
    when(mockInitializer.initializeApp()).thenAnswer((_) => Future.value(mockApp));

    // Pass the mockInitializer to MyApp
    await tester.pumpWidget(MyApp());


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
