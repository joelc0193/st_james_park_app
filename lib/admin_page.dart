import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
  String _password = '';
  String _newNumber = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            CustomTextFormField(
              labelText: 'Password',
              onChanged: (value) {
                setState(() {
                  _password = value;
                });
              },
            ),
            CustomTextFormField(
              labelText: 'New Number',
              onChanged: (value) {
                setState(() {
                  _newNumber = value;
                });
              },
            ),
            ElevatedButton(
              child: const Text('Update Number'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await _firestoreService.incrementNumber(
                        'numbers/currentNumber', 1);
                  } catch (e) {
                    print(e);
                  }
                }
              },
            ),
          ],
        ),
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
