import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';

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
  //     await firestore.collection('featured_member').doc('image').set({
  //       'url': imageUrl,
  //     });
  //     return imageUrl;
  //   } catch (e) {
  //     print(e);
  //     throw e;
  //   }
  // }

  Future<String> uploadImage(PickedFile pickedFile) async {
    Uint8List bytes = await pickedFile.readAsBytes();
    String fileName = pickedFile.path.split('/').last;
    Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    UploadTask uploadTask = firebaseStorageRef.putData(bytes);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    // Update Firestore with the new image URL
    await firestore.collection('featured_member').doc('featured_member').set({
      'image_url': downloadUrl,
    });

    return downloadUrl;
  }

  Future<String?> getFeaturedImageUrl() async {
    DocumentSnapshot doc = await firestore
        .collection('featured_member')
        .doc('featured_member')
        .get();
    Map<String, dynamic>? data = doc.data()! as Map<String, dynamic>?;
    return data?['image_url'] as String?;
  }
}
