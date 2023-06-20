import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/edit_profile_page.dart';

import 'login_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  late User loggedInUser;
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
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    setState(() {
      userName = null;
      userEmail = null;
      userImage = null;
      userMessage = null;
      isLoggedIn = false; // Set isLoggedIn to false after signing out
    });
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUser.uid)
            .get();
        setState(() {
          userName = doc.get('name');
          userEmail = loggedInUser.email;
          userImage = doc.get('image_url');
          userMessage = doc.get('user_message'); // Fetch the user message
          isLoggedIn = true; // Set isLoggedIn to true after fetching user data
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading =
            false; // Set isLoading to false regardless of whether the user is logged in or not
      });
    }
  }

  Future<void> signIn() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        loggedInUser = userCredential.user!;
        getCurrentUser();
        setState(() {
          isLoggedIn = true; // Set isLoggedIn to true after successful login
        });
      } catch (e) {
        print('Error signing in: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update the build method to display different UI based on the login status
    if (isLoading) {
      return Center(
          child:
              CircularProgressIndicator()); // Show loading spinner while isLoading is true
    } else if (isLoggedIn) {
      return profilePage(); // Display the profile page if the user is logged in
    } else {
      return LoginPage(); // Display the login form if the user is not logged in
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
                    child: Container(
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
              child: Text('${userMessage ?? 'Not available'}'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      initialUserName: userName,
                      initialUserMessage: userMessage,
                      initialUserImage: userImage,
                      loggedInUser: loggedInUser, // Pass loggedInUser here
                    ),
                  ),
                );
              },
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
