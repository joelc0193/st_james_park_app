import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

void main() {
  group('FirestoreService', () {
    late FirestoreService firestoreService;
    late FakeFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      firestoreService =
          FirestoreService(firestore: mockFirestore, auth: mockAuth);

      mockFirestore
          .collection('numbers')
          .doc('currentNumber')
          .set({'currentNumber': 0});
    });

    test('incrementNumber increases the number in Firestore', () async {
      await firestoreService.incrementNumber();

      var snapshot =
          await mockFirestore.collection('numbers').doc('currentNumber').get();
      var data = snapshot.data();
      expect(data?['currentNumber'], 1);
    });
  });
}