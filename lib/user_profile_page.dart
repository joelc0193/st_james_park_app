import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/edit_profile_page.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/listing.dart';

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
  String? userImage;
  String? userMessage;
  String? email;
  String? password;
  bool isSigningUp = true;
  bool isLoggedIn = false;
  bool isLoading = true;
  List<Listing> services = [];
  late FirestoreService _firestoreService;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    _authService = Provider.of<AuthService>(context, listen: false);
    _firestoreService = FirestoreService(firestore: FirebaseFirestore.instance);
    await getCurrentUserAndData();
  }

  Future<void> getCurrentUserAndData() async {
    loggedInUser = _authService.getCurrentUser();
    if (loggedInUser != null) {
      isLoggedIn = true;
      final userData = await _firestoreService.getUserData(loggedInUser!.uid);
      userName = userData?.name;
      userImage = userData?.imageUrl;
      userMessage = userData?.message;
    } else {
      isLoggedIn = false;
      userName = null;
      userImage = null;
      userMessage = null;
      services = [];
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthService>();
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (isLoggedIn) {
      return profilePage();
    } else {
      return const LoginPage();
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
                      width: 150,
                      height: 150,
                      child: Image.network(
                        userImage!,
                        fit: BoxFit.cover,
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
                      loggedInUser: loggedInUser!,
                      initialUserName: userName,
                      initialUserMessage: userMessage,
                      initialUserImage: userImage,
                    ),
                  ),
                ).then((_) => getCurrentUserAndData());
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
