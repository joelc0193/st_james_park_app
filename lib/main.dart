import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'St James Park',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        firestoreService: FirestoreService(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final FirestoreService firestoreService;

  const MyHomePage({
    Key? key,
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
      title: 'Flutter Demo',
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
                  await widget.firestoreService.signUp(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                },
                child: Text('Sign Up'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.firestoreService.logIn(
                    email: _emailController.text,
                    password: _passwordController.text,
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
