import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/admin_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirestoreService _firestoreService;
  late AuthService _authService;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _firestoreService = Provider.of<FirestoreService>(context);

    _authService = AuthService(
      auth: Provider.of<FirebaseAuth>(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('St James Park Home Page'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          CustomTextField(controller: _emailController, hintText: 'Email'),
          CustomTextField(
              controller: _passwordController, hintText: 'Password'),
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getNumber(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              return CountWidget(snapshot);
            },
          ),
          CustomButton(
            title: 'Sign Up',
            onPressed: () async {
              try {
                await _authService.createUserWithEmailAndPassword(
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
            },
          ),
          CustomButton(
            title: 'Log In',
            onPressed: () async {
              try {
                await _authService.signInWithEmailAndPassword(
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
            },
          ),
          CustomButton(
            title: 'Sign Out',
            onPressed: () async {
              try {
                await _authService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully Logged Out')),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed with ${e.message}')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _firestoreService.incrementNumber();
        },
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
}

class CountWidget extends StatelessWidget {
  final snapshot;
  CountWidget(
    AsyncSnapshot<DocumentSnapshot<Object?>> this.snapshot, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const Text('Something went wrong', key: Key('numberText'));
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text("Loading", key: Key('numberText'));
    }
    if (snapshot.connectionState == ConnectionState.active) {
      if (snapshot.data!.exists) {
        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;
        return Text("${data['currentNumber']}", key: Key('numberText'));
      } else {
        return Text('Document does not exist', key: Key('numberText'));
      }
    }
    return Text('$snapshot', key: Key('numberText'));
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  CustomTextField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hintText,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  CustomButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }
}
