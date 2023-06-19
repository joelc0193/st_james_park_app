import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserMessage;
  final String? initialUserImage;
  final User loggedInUser; // Add this line

  EditProfilePage({
    this.initialUserName,
    this.initialUserMessage,
    this.initialUserImage,
    required this.loggedInUser, // And this line
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController? userNameController;
  TextEditingController? userMessageController;
  TextEditingController? userImageController;

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController(text: widget.initialUserName);
    userMessageController =
        TextEditingController(text: widget.initialUserMessage);
    userImageController = TextEditingController(text: widget.initialUserImage);
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();

    // Get the FirebaseStorage instance from the Provider
    final storage = Provider.of<FirebaseStorage>(context, listen: false);

    // Show a dialog to the user to choose between Camera and Gallery
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
              child: const Text('Camera'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'gallery');
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );

    final XFile? image = await _picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );

    if (image != null) {
      final File file = File(image.path);
      // Upload the file to Firebase Storage and get the download URL
      try {
        final ref = storage.ref().child('user_images').child(
            '${widget.loggedInUser.uid}.jpg'); // Use widget.loggedInUser here
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();
        // Update the userImageController with the new download URL
        userImageController!.text = downloadUrl;
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: userNameController,
              decoration: InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: userMessageController,
              decoration: InputDecoration(
                labelText: 'Message',
              ),
            ),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Select Image'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save the changes to Firestore here
                // Then pop the page
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
