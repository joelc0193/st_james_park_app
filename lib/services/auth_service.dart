import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({required FirebaseAuth auth}) : _auth = auth;

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Failed to sign up: $e');
      rethrow;
    }
  }

  Future<UserCredential> logIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Failed to log in: $e');
      rethrow;
    }
  }

  Future<void> logOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Failed to log out: $e');
      rethrow;
    }
  }
}
