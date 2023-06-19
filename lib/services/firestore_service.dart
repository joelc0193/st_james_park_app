import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseFirestore firestore;

  FirestoreService({required this.firestore});

  FieldValue getServerTimestamp() {
    return FieldValue.serverTimestamp();
  }

  Stream<DocumentSnapshot> getAdminNumbers() {
    return firestore.collection('numbers').doc('numbers').snapshots();
  }

  Future<void> updateAdminNumbers(Map<String, int> numbers) async {
    await firestore.collection('numbers').doc('numbers').set({
      ...numbers,
      'Updated': getServerTimestamp(),
    });
  }

  // Future<String> uploadImage(File imageFile) async {
  //   try {
  //     String fileName = DateTime.now().millisecondsSinceEpoch.toString();

  //     FirebaseStorage storage = FirebaseStorage.instance;
  //     Reference reference = storage.ref().child(fileName);
  //     UploadTask uploadTask = reference.putFile(imageFile);
  //     TaskSnapshot storageTaskSnapshot = await uploadTask;

  //     var imageUrl = await storageTaskSnapshot.ref.getDownloadURL();
  //     await firestore.collection('spotlight').doc('image').set({
  //       'url': imageUrl,
  //     });
  //     return imageUrl;
  //   } catch (e) {
  //     print(e);
  //     throw e;
  //   }
  // }

  Future<String> uploadMedia(Uint8List? mediaData) async {
    if (mediaData != null) {
      String fileName =
          'uploads/${DateTime.now().toIso8601String()}'; // Generate a unique file name
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putData(mediaData);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with the new media URL
      await firestore.collection('spotlight').doc('spotlight').update({
        'media_url': downloadUrl,
      });

      return downloadUrl;
    } else {
      // Update Firestore with an empty string if no media is selected
      await firestore.collection('spotlight').doc('spotlight').update({
        'media_url': '',
      });

      return '';
    }
  }

  Future<void> uploadText(String text) async {
    try {
      await firestore.collection('spotlight').doc('spotlight').update({
        'message': text,
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<String?> getUploadedText() async {
    DocumentSnapshot doc =
        await firestore.collection('spotlight').doc('spotlight').get();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return data?['message'] as String?;
  }

  Future<String?> getSpotlightImageUrl() async {
    DocumentSnapshot doc =
        await firestore.collection('spotlight').doc('spotlight').get();
    Map<String, dynamic>? data = doc.data()! as Map<String, dynamic>?;
    return data?['image_url'] as String?;
  }
}
