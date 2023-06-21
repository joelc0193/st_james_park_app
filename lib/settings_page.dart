import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/auth_service.dart';

class SettingsPage extends StatelessWidget {

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: authService.signOut,
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
