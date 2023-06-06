import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _passwordController = TextEditingController();
  final _numberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _password = 'your_password';  // Replace with your actual password

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value != _password) {
                    return 'Incorrect password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(labelText: 'New Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a number';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Update the number
                    Navigator.pop(context, int.parse(_numberController.text));
                  }
                },
                child: Text('Update Number'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
