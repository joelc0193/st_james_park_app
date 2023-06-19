import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserMessage;
  final String? initialUserImage;

  EditProfilePage(
      {this.initialUserName, this.initialUserMessage, this.initialUserImage});

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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final File file = File(image.path);
      // Upload the file to Firebase Storage and get the download URL
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${loggedInUser.uid}.jpg');
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
