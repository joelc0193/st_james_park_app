import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({required FirebaseAuth auth}) : _auth = auth;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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
    return _auth.currentUser?.uid;
  }
}
