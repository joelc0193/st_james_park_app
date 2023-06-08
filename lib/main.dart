import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './services/firestore_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirestoreService _firestoreService = FirestoreService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Home Page'),
      ),
      body: Column(
        children: <Widget>[
          _buildEmailField(),
          _buildPasswordField(),
          _buildNumberStream(),
          _buildSignUpButton(),
          _buildLogInButton(),
          _buildLogOutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementNumber,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
    );
  }

  Widget _buildNumberStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getNumber(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data!.exists) {
            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
            return Text("Data: ${data['currentNumber']}");
          } else {
            return Text('Document does not exist');
          }
        }

        return const Text('Unknown state');
      },
    );
  }

  void _incrementNumber() async {
    await _firestoreService.incrementNumber();
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      child: const Text('Sign Up'),
      onPressed: _signUp,
    );
  }

  Widget _buildLogInButton() {
    return ElevatedButton(
      child: const Text('Log In'),
      onPressed: _logIn,
    );
  }

  Widget _buildLogOutButton() {
    return ElevatedButton(
      onPressed: _logOut,
      child: const Text('Log Out'),
    );
  }

  void _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully Signed Up')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed with ${e.message}')),
      );
    }
  }

  void _logIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully Logged In')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed with ${e.message}')),
      );
    }
  }

  void _logOut() async {
    await _firestoreService.logOut();
  }
}
