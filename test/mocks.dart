import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
