import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ValueNotifier<bool> isUserLoggedIn = ValueNotifier<bool>(false);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? email;
  String? password;
  String? userName;
  bool isSigningUp = true;

  Future<void> signUp() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        isUserLoggedIn.value = true;
      } catch (e) {
        print('Error signing up: $e');
      }
    }
  }

  Future<void> signIn() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        isUserLoggedIn.value = true;
      } catch (e) {
        print('Error signing in: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isSigningUp ? signUpForm() : loginForm();
  }

  Widget signUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            validator: (input) => input != null && input.contains('@')
                ? null
                : 'Please enter a valid email',
            onSaved: (input) => email = input,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextFormField(
            validator: (input) => input != null && input.length >= 6
                ? null
                : 'Your password needs to be at least 6 characters',
            onSaved: (input) => password = input,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          TextFormField(
            onSaved: (input) => userName = input,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          ElevatedButton(
            onPressed: signUp,
            child: const Text('Sign Up'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isSigningUp = false;
              });
            },
            child: const Text('Already have an account? Log In'),
          ),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            validator: (input) => input != null && input.contains('@')
                ? null
                : 'Please enter a valid email',
            onSaved: (input) => email = input,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextFormField(
            validator: (input) => input != null && input.length >= 6
                ? null
                : 'Your password needs to be at least 6 characters',
            onSaved: (input) => password = input,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {
              signIn();
              setState(() {
                isSigningUp = false;
              });
            },
            child: const Text('Log In'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isSigningUp = true;
              });
            },
            child: const Text('Don\'t have an account? Sign Up'),
          ),
        ],
      ),
    );
  }
}
