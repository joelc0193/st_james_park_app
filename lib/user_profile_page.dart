import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/edit_profile_page.dart';

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
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': 'John Doe',
      'image_url': 'https://via.placeholder.com/150',
      'user_message':
          'This is my profile!', // Replace with the actual user message
    });

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
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> signUp() async {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        loggedInUser = userCredential.user!;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUser.uid)
            .set({
          'name': userName,
          'image_url': 'https://via.placeholder.com/150',
          'user_message': 'This is my profile!',
        });
        getCurrentUser();
        setState(() {
          isSigningUp = false;
          isLoggedIn = true; // Set isLoggedIn to true after successful signup
        });
      } catch (e) {
        print('Error signing up: $e');
      }
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
    if (isLoggedIn) {
      return profilePage(); // Display the profile page if the user is logged in
    } else {
      return isSigningUp
          ? signUpForm()
          : loginForm(); // Display the signup or login form if the user is not logged in
    }
  }

  Widget signUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            validator: (input) => input != null && input.contains('@')
                ? null
                : 'Please enter a valid email',
            onSaved: (input) => email = input,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextFormField(
            validator: (input) => input != null && input.length >= 6
                ? null
                : 'Your password needs to be at least 6 characters',
            onSaved: (input) => password = input,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          TextFormField(
            onSaved: (input) => userName = input,
            decoration: InputDecoration(
              labelText: 'Name',
            ),
          ),
          ElevatedButton(
            onPressed: signUp,
            child: Text('Sign Up'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isSigningUp = false;
              });
            },
            child: Text('Already have an account? Log In'),
          ),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            validator: (input) => input != null && input.contains('@')
                ? null
                : 'Please enter a valid email',
            onSaved: (input) => email = input,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextFormField(
            validator: (input) => input != null && input.length >= 6
                ? null
                : 'Your password needs to be at least 6 characters',
            onSaved: (input) => password = input,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () {
              signIn();
              setState(() {
                isSigningUp = false;
              });
            },
            child: Text('Log In'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isSigningUp = true;
              });
            },
            child: Text('Don\'t have an account? Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget profilePage() {
    return Scaffold(
      backgroundColor: Colors.green, // Set the background color to green
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Welcome, ${userName ?? 'User'}!'),
              userImage != null
                  ? ClipOval(
                      child:
                          Image.network(userImage!)) // Make the image circular
                  : Container(),
              Text('${userMessage ?? 'Not available'}'),
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
              ElevatedButton(
                onPressed: signOut,
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
