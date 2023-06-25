import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      return {
        'name': doc.get('name'),
        'email': user.email,
        'image_url': doc.get('image_url'),
        'user_message': doc.get('user_message'),
      };
    }
    return {};
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
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
