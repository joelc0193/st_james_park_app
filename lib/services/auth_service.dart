import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({required FirebaseAuth auth}) : _auth = auth;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> signInWithEmailAndPassword(
      {required email, required password}) async {
        print('************about to call _auth.signInWithEmailAndPassword');
    _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createUserWithEmailAndPassword(
      {required email, required password}) async {
    _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
