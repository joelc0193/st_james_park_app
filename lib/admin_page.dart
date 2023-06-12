import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/auth_service.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  late AuthService _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = AuthService(
      auth: Provider.of<FirebaseAuth>(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Padding(
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

  void _submitForm() {
    if (_authService.isUserSignedIn()) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        // TODO: Implement your logic to upload the data to Firestore
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
