import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  late AuthService _authService;
  late FirestoreService _firestoreService;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = AuthService(
      auth: Provider.of<FirebaseAuth>(context),
    );
    _firestoreService = Provider.of<FirestoreService>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body:
          _authService.isUserSignedIn() ? _buildAdminForm() : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          CustomTextField(controller: _emailController, hintText: 'Email'),
          CustomTextField(
              controller: _passwordController, hintText: 'Password'),
          CustomButton(
            title: 'Sign In',
            onPressed: () async {
              try {
                await _authService.signInWithEmailAndPassword(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully Logged In')),
                );
                setState(() {}); // Update the UI after successful login
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed with ${e.message}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNumberField('Basketball Courts'),
              _buildNumberField('Tennis Courts'),
              _buildNumberField('Soccer Field'),
              _buildNumberField('Playground'),
              _buildNumberField('Handball Court'),
              _buildNumberField('Other'),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label) {
    return TextFormField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a number';
        }
        return null;
      },
      onSaved: (value) {
        _formData[label] = value!;
      },
    );
  }

  void _submitForm() async {
    if (_authService.isUserSignedIn()) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        // Save the data to Firestore
        try {
          await Provider.of<FirestoreService>(context, listen: false)
              .updateAdminNumbers(_formData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Numbers updated successfully'),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update numbers: $e'),
            ),
          );
        }
        print(_formData);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be signed in to submit data'),
        ),
      );
    }
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  CustomButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(title),
    );
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
