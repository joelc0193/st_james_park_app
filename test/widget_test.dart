// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
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
import 'package:mockito/annotations.dart';

import 'widget_test.mocks.dart';

@GenerateMocks(
    [FirebaseFirestore, FirebaseAuth, FirestoreService, DocumentSnapshot])
void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Arrange:
    TestWidgetsFlutterBinding.ensureInitialized();

    final MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
    final MockFirebaseAuth mockAuth = MockFirebaseAuth();
    final MockFirestoreService mockFirestoreService = MockFirestoreService();
    final MockDocumentSnapshot mockDocumentSnapshot1 = MockDocumentSnapshot();
    final MockDocumentSnapshot mockDocumentSnapshot2 = MockDocumentSnapshot();

    var controller = StreamController<DocumentSnapshot>();
    controller.add(mockDocumentSnapshot1);

    var controller1 = StreamController<DocumentSnapshot>();

    when(mockFirestoreService.getNumber()).thenAnswer((_) => controller.stream);
    when(mockDocumentSnapshot1.exists).thenAnswer((_) => true);
    when(mockDocumentSnapshot1.data()).thenAnswer((_) => {'currentNumber': 0});
    when(mockDocumentSnapshot2.exists).thenAnswer((_) => true);

    when(mockDocumentSnapshot2.data()).thenAnswer((_) => {'currentNumber': 1});
    when(mockFirestoreService.getAdminNumbers()).thenAnswer((_) => controller1.stream);
    when(mockFirestoreService.getNumber()).thenAnswer((_) => controller.stream);
    when(mockFirestoreService.incrementNumber()).thenAnswer((_) async {
      controller.add(mockDocumentSnapshot2);
      return Future.value();
    });

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

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.admin_panel_settings));
    await tester.pumpAndSettle();

    controller.close();
  });
}
