import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/auth_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _firestoreService = FirestoreService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
  final _authService = AuthService(
    auth: FirebaseAuth.instance,
  );
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: <Widget>[
          CustomTextFormField(
            labelText: 'Email',
            onChanged: (value) {
              setState(() {
                _email = value;
              });
            },
          ),
          CustomTextFormField(
            labelText: 'Password',
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: _firestoreService.getNumber(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text('Data: ${snapshot.data}');
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return const CircularProgressIndicator();
            },
          ),
          ElevatedButton(
            child: const Text('Sign Up'),
            onPressed: () async {
              try {
                await _authService.signUp(_email, _password);
              } catch (e) {
                print(e);
              }
            },
          ),
          ElevatedButton(
            child: const Text('Log In'),
            onPressed: () async {
              try {
                await _authService.logIn(_email, _password);
              } catch (e) {
                print(e);
              }
            },
          ),
          ElevatedButton(
            child: const Text('Log Out'),
            onPressed: () async {
              try {
                await _authService.logOut();
              } catch (e) {
                print(e);
              }
            },
          ),
        ],
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final String labelText;
  final Function(String) onChanged;

  CustomTextFormField({required this.labelText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: labelText),
      onChanged: onChanged,
    );
  }
}
