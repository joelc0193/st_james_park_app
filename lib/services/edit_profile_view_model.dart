import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/service.dart';

class EditProfileViewModel with ChangeNotifier {
  final FirestoreService _firestoreService;
  final User _loggedInUser;

  EditProfileViewModel(
      {required FirestoreService firestoreService, required User loggedInUser})
      : _firestoreService = firestoreService,
        _loggedInUser = loggedInUser;

  String? userImageUrl;
  File? imageFile;
  List<Service> services = [];
  String? error;

  Future<void> fetchServices() async {
    try {
      List<Service> fetchedServices =
          await _firestoreService.getServicesForUser(_loggedInUser.uid);
      services = fetchedServices;
      notifyListeners(); // Notify the View of the change
    } catch (e) {
      error = 'Failed to fetch services: $e';
      notifyListeners(); // Notify the View of the error
    }
  }

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      throw Exception('No image selected');
    }
  }

  Future<Service> addService(Service newService) async {
    String newServiceId = await _firestoreService.addService(
      _loggedInUser.uid,
      newService,
    );
    newService = newService.copyWith(id: newServiceId);
    return newService;
  }

  Future<String> uploadImage(File? imageFile) async {
    if (imageFile == null) {
      throw Exception('No image selected');
    }
    return await _firestoreService.uploadImage(imageFile);
  }

  Future<void> editService(Service updatedService) async {
    int index =
        services.indexWhere((service) => service.id == updatedService.id);
    if (index != -1) {
      services[index] = updatedService;
      await _firestoreService.updateService(
          _loggedInUser.uid, updatedService, imageFile);
    } else {
      throw Exception('Service not found');
    }
  }

  Future<void> deleteService(int index) async {
    String serviceId = services[index].id;
    String imageUrl = services[index].imageUrl;
    services.removeAt(index);
    await _firestoreService.deleteService(
        _loggedInUser.uid, serviceId, imageUrl);
  }

  Future<String?> updateUserProfile(
      String name,
      String message,
      String imageUrl,
      List<String> interests, // new parameter
      List<String> goals // new parameter
      ) async {
    if (name.isEmpty) {
      return 'Name cannot be empty.';
    }
    if (message.isEmpty) {
      return 'Message cannot be empty.';
    }
    if (imageUrl.isEmpty) {
      return 'Please select an image.';
    }

    await _firestoreService.updateUserProfile(
        _loggedInUser.uid,
        name,
        message,
        imageUrl,
        interests, // pass the interests
        goals // pass the goals
        );
    return null; // return null if there's no error
  }
}
