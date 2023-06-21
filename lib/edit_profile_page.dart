import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserMessage;
  final String? initialUserImage;
  final User loggedInUser;

  const EditProfilePage({super.key, 
    this.initialUserName,
    this.initialUserMessage,
    this.initialUserImage,
    required this.loggedInUser,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController? userNameController;
  TextEditingController? userMessageController;
  String? userImageUrl;

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController(text: widget.initialUserName);
    userMessageController =
        TextEditingController(text: widget.initialUserMessage);
    userImageUrl = widget.initialUserImage;
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final storage = Provider.of<FirebaseStorage>(context, listen: false);

    final String? source = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Image Source'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'camera');
              },
              child: const Text('Camera',
                  style: TextStyle(color: Colors.black)), // Change color here
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'gallery');
              },
              child: const Text('Gallery',
                  style: TextStyle(color: Colors.black)), // And here
            ),
          ],
        );
      },
    );

    final XFile? image = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );

    if (image != null) {
      final File file = File(image.path);
      try {
        final ref = storage
            .ref()
            .child('user_images')
            .child('${widget.loggedInUser.uid}.jpg');
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();
        setState(() {
          userImageUrl = downloadUrl;
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: userNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: userMessageController,
              decoration: const InputDecoration(
                labelText: 'Message',
              ),
            ),
            if (userImageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ClipOval(
                  child: Image.network(
                    userImageUrl!,
                    width: 150.0, // Specify the width
                    height: 150.0, // Specify the height
                    fit: BoxFit
                        .cover, // Use BoxFit.cover to maintain the aspect ratio
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Select Image'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (userNameController!.text.isNotEmpty &&
                    userMessageController!.text.isNotEmpty &&
                    userImageUrl != null) {
                  try {
                    // Update the user's profile
                    await firestoreService.updateUserProfile(
                      widget.loggedInUser.uid,
                      userNameController!.text,
                      userMessageController!.text,
                      userImageUrl!,
                    );
                    // Navigate back to the previous page
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error updating profile: $e');
                  }
                } else {
                  // Show an error message if the form is not completely filled out
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please fill out all fields and select an image.'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
