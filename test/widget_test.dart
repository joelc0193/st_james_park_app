import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:st_james_park_app/main.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  final mockFirestore = MockFirestoreInstance();
  final mockAuth = MockFirebaseAuth();
  final firestoreService = FirestoreService(
    firestore: mockFirestore,
    auth: mockAuth,
  );
  final authService = AuthService(
    auth: mockAuth,
  );

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(
      firestoreService: firestoreService,
      authService: authService,
    ));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
