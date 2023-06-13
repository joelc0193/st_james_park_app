import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:mockito/annotations.dart';

import 'mocks.dart';
import 'firestore_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot
])
void main() {
  group('FirestoreService', () {
    late MockFirebaseFirestore mockFirestore;
    late FirestoreService firestoreService;
    late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollectionReference = MockCollectionReference<Map<String, dynamic>>();
      mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();
      firestoreService = FirestoreService(firestore: mockFirestore);
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
      controller.add(mockDocumentSnapshot);
    });

    test('getNumber returns the current number from Firestore', () async {
      // Setup:
      when(mockFirestore.collection('numbers'))
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('currentNumber'))
          .thenReturn(mockDocumentReference);
      when(mockDocumentReference.snapshots())
          .thenAnswer((_) => controller.stream);

      // Action: Call getNumber().
      firestoreService.getNumber();

      // Assert: Correct Firestore call was made
      verify(mockDocumentReference.snapshots()).called(1);
    });

    test('getAdminNumbers returns the admin numbers from Firestore', () async {
      // Setup:
      when(mockFirestore.collection('numbers'))
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('adminNumbers'))
          .thenReturn(mockDocumentReference);
      when(mockDocumentReference.snapshots())
          .thenAnswer((_) => controller.stream);

      // Action: Call getNumber().
      firestoreService.getAdminNumbers();

      // Assert: Correct Firestore call was made
      verify(mockDocumentReference.snapshots()).called(1);
    });

    test('incrementNumber increases the number in Firestore', () async {
      // Setup:
      when(mockFirestore.collection('numbers')).thenAnswer((_) =>
          mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.doc('currentNumber'))
          .thenAnswer((_) => mockDocumentReference);
      when(mockDocumentReference.snapshots())
          .thenAnswer((_) => controller.stream);
      when(mockDocumentReference.get())
          .thenAnswer((_) => Future.value(mockDocumentSnapshot));
      when(mockDocumentSnapshot.exists).thenAnswer((_) => true);
      when(mockDocumentSnapshot.data()).thenAnswer((_) => {'currentNumber': 0});
      when(mockDocumentReference.update({'currentNumber': 1}))
          .thenAnswer((_) => Future.value());

      // Action: Call incrementNumber().
      await firestoreService.incrementNumber();

      // Assert: Correct Firestore call was made.
      verify(mockDocumentReference.update({'currentNumber': 1})).called(1);
    });

    test('updateAdminNumbers updates the admin numbers in Firestore', () async {
      // Setup:
      DateTime now = DateTime.now();
      when(mockFirestore.collection('numbers')).thenAnswer((_) =>
          mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.doc('adminNumbers'))
          .thenAnswer((_) => mockDocumentReference);
      when(mockDocumentReference.snapshots())
          .thenAnswer((_) => controller.stream);
      var newAdminNumbers = {
        'Basketball Courts': 1,
        'Handball Courts': 1,
        'Tennis Courts': 1,
        'Playground': 1,
        'Soccer Field': 1,
        'Other': 0,
      };
      when(mockDocumentReference.set(newAdminNumbers))
          .thenAnswer((_) => Future.value());

      // Action: Call incrementNumber().
      await firestoreService.updateAdminNumbers(newAdminNumbers);

      // Assert: Correct Firestore call was made.
      verify(mockDocumentReference.set(
        argThat(
          isA<Map>().having(
            (m) => m..remove('Last Update'),
            'map without Last Update',
            {
              'Basketball Courts': 1,
              'Handball Courts': 1,
              'Tennis Courts': 1,
              'Playground': 1,
              'Soccer Field': 1,
              'Other': 0,
            },
          ),
        ),
      )).called(1);
    });

    tearDown(() => {controller.close()});
  });
}
