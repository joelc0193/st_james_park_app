import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:mockito/annotations.dart';

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

    test('getAdminNumbers returns the admin numbers from Firestore', () async {
      // Setup:
      when(mockFirestore.collection('numbers'))
          .thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('numbers'))
          .thenReturn(mockDocumentReference);
      when(mockDocumentReference.snapshots())
          .thenAnswer((_) => controller.stream);

      // Action: Call getNumber().
      firestoreService.getAdminNumbers();

      // Assert: Correct Firestore call was made
      verify(mockDocumentReference.snapshots()).called(1);
    });

    test('updateAdminNumbers updates the admin numbers in Firestore', () async {
      // Setup:
      when(mockFirestore.collection('numbers')).thenAnswer((_) =>
          mockCollectionReference);
      when(mockCollectionReference.doc('numbers'))
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
            (m) => m..remove('Updated'),
            'map without Updated',
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
