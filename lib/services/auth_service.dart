import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/listing.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth _auth;

  AuthService({required FirebaseAuth auth}) : _auth = auth;

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get userState => _auth.userChanges();

  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = getCurrentUser();
    if (user != null) {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final QuerySnapshot serviceSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('services')
          .get();

      // Convert each service document to a Service object
      final services = serviceSnapshot.docs.map((serviceDoc) {
        return Listing.fromMap(
            serviceDoc.id, serviceDoc.data() as Map<String, dynamic>);
      }).toList();

      return {
        'name': doc.get('name'),
        'imageUrl': doc.get('imageUrl'),
        'message': doc.get('message'),
        'services': services,
      };
    }
    return {};
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email,
      required String password,
      required String name}) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create a new document in Firestore for the new user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'name': name,
      'imageUrl':
          'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
      'message': '',
    });

    notifyListeners();

    return userCredential;
  }

  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }

  // Add this method
  String? getCurrentUserId() {
    return getCurrentUser()?.uid;
  }

  void update({required FirebaseAuth auth}) {
    _auth = auth;
  }
}
