import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/edit_profile_page.dart';
import 'package:st_james_park_app/services/auth_service.dart';

import 'login_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late AuthService _authService;
  final _formKey = GlobalKey<FormState>();
  late User? loggedInUser;
  String? userName;
  String? userEmail;
  String? userImage;
  String? userMessage;
  String? email;
  String? password;
  bool isSigningUp = true;
  bool isLoggedIn = false;
  bool isLoading = true; // Add this line

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    _authService =
        _authService = Provider.of<AuthService>(context, listen: false);
    await getCurrentUserAndData();
  }

  Future<void> getCurrentUserAndData() async {
    loggedInUser = _authService.getCurrentUser();
    if (loggedInUser != null) {
      isLoggedIn = true;
      final userData = await _authService.getCurrentUserData();
      userName = userData['name'];
      userEmail = userData['email'];
      userImage = userData['image_url'];
      userMessage = userData['user_message'];
    } else {
      isLoggedIn = false;
      userName = null;
      userEmail = null;
      userImage = null;
      userMessage = null;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthService>();
    // Update the build method to display different UI based on the login status
    if (isLoading) {
      return const Center(
          child:
              CircularProgressIndicator()); // Show loading spinner while isLoading is true
    } else if (isLoggedIn) {
      return profilePage(); // Display the profile page if the user is logged in
    } else {
      return const LoginPage(); // Display the login form if the user is not logged in
    }
  }

  Widget profilePage() {
    return Center(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Welcome, ${userName ?? 'User'}!'),
            ),
            userImage != null
                ? ClipOval(
                    child: SizedBox(
                      width: 150, // Set width
                      height: 150, // Set height
                      child: Image.network(
                        userImage!,
                        fit: BoxFit
                            .cover, // Use BoxFit.cover to maintain the aspect ratio
                      ),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(userMessage ?? 'Not available'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      loggedInUser: loggedInUser!, // Pass loggedInUser here
                    ),
                  ),
                );
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
