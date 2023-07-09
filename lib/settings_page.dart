import 'package:flutter/material.dart';
import 'package:st_james_park_app/services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  AuthService authService;

  SettingsPage(this.authService, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await authService.signOut();
            Navigator.pop(context);
          },
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
