import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './services/firestore_service.dart';
import './services/auth_service.dart';  // Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(auth: FirebaseAuth.instance);  // Create an instance of AuthService
    final firestoreService = FirestoreService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );

    return MaterialApp(
      title: 'St James Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        authService: authService,  // Pass authService to MyHomePage
        firestoreService: firestoreService,  // Pass firestoreService to MyHomePage
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final AuthService authService;  // Add authService field
  final FirestoreService firestoreService;

  const MyHomePage({
    Key? key,
    required this.authService,  // Add authService to constructor
    required this.firestoreService,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St James Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('St James Park'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.authService.signUp(
                    _emailController.text,
                    _passwordController.text,
                  );
                },
                child: Text('Sign Up'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.authService.logIn(
                    _emailController.text,
                    _passwordController.text,
                  );
                },
                child: Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
