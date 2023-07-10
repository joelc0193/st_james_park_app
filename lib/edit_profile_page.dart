import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:st_james_park_app/services/edit_profile_view_model.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/service.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialUserName;
  final String? initialUserMessage;
  final String? initialUserImage;
  final User loggedInUser;

  const EditProfilePage({
    Key? key,
    this.initialUserName,
    this.initialUserMessage,
    this.initialUserImage,
    required this.loggedInUser,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController userMessageController = TextEditingController();
  String? userImageUrl;
  late FirestoreService firestoreService;
  File? imageFile;
  late EditProfileViewModel? viewModel;

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController(text: widget.initialUserName);
    userMessageController =
        TextEditingController(text: widget.initialUserMessage);
    userImageUrl = widget.initialUserImage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (viewModel == null) {
      firestoreService = Provider.of<FirestoreService>(context, listen: false);
      viewModel = EditProfileViewModel(
        firestoreService: firestoreService,
        loggedInUser: widget.loggedInUser,
      );
      try {
        viewModel!.fetchServices();
        viewModel!.addListener(_updateState);
      } catch (e) {
        // Handle the error here. You could show a Snackbar with the error message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch services: $e')),
        );
      }
    }
  }

  void _updateState() {
    if (viewModel!.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel!.error!)),
      );
    } else {
      // Update the UI with the new state
    }
  }

  void fetchServices() async {
    // Replace this with the actual code to fetch the services from Firebase
    List<Service> fetchedServices =
        await firestoreService.getServicesForUser(widget.loggedInUser.uid);

    setState(() {
      viewModel!.services = fetchedServices;
    });
  }

  Future<File?> pickImage() async {
    final ImagePicker picker = ImagePicker();
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
              child:
                  const Text('Camera', style: TextStyle(color: Colors.black)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'gallery');
              },
              child:
                  const Text('Gallery', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final pickedFile = await picker.getImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        throw Exception('No image selected');
      }
    } else {
      throw Exception('No image source selected');
    }
  }

  void addService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController typeController = TextEditingController();
        TextEditingController descriptionController = TextEditingController();
        TextEditingController priceController = TextEditingController();
        String? imageUrl;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Add Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        File? newImageFile = await viewModel!.pickImage();
                        dialogSetState(() {
                          imageFile = newImageFile;
                        });
                      } catch (e) {
                        print('Error picking image: $e');
                      }
                    },
                    child: const Text('Select Image'),
                  ),
                  if (imageFile != null)
                    Image(
                      image: FileImage(imageFile!),
                      errorBuilder: (context, error, stackTrace) {
                        return Text('Error loading image: $error');
                      },
                    ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    if (imageFile != null) {
                      imageUrl = await viewModel!.uploadImage(imageFile!);
                    }
                    Service newService = Service(
                      id: '',
                      type: typeController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      imageUrl: imageUrl ?? '',
                      userId: widget.loggedInUser.uid,
                    );
                    Service addedService =
                        await viewModel!.addService(newService);
                    Navigator.of(context).pop(addedService);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((newService) {
      if (newService != null) {
        setState(() {
          viewModel!.services.add(newService);
        });
      }
    });
  }

  void editService(int index) {
    TextEditingController typeController =
        TextEditingController(text: viewModel!.services[index].type);
    TextEditingController descriptionController =
        TextEditingController(text: viewModel!.services[index].description);
    TextEditingController priceController = TextEditingController(
        text: viewModel!.services[index].price.toString());
    String? imageUrl = viewModel!.services[index].imageUrl;
    File? imageFile;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Service'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      imageFile = await pickImage();
                      setState(() {});
                    },
                    child: const Text('Select Image'),
                  ),
                  Flexible(
                    child: imageFile != null
                        ? Image.file(imageFile!)
                        : (imageUrl != null
                            ? Image.network(imageUrl!)
                            : Container()),
                  ),
                ],
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (imageFile != null) {
                      imageUrl = await firestoreService.uploadImage(imageFile!);
                    }
                    Service updatedService = Service(
                      id: viewModel!.services[index].id,
                      type: typeController.text,
                      description: descriptionController.text,
                      price: double.parse(priceController.text),
                      imageUrl: imageUrl ?? '',
                      userId: widget.loggedInUser.uid,
                    );
                    await viewModel!.editService(updatedService);
                    Navigator.of(context).pop(updatedService);
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((updatedService) {
      if (updatedService != null) {
        setState(() {});
      }
    });
  }

  void deleteService(int index) {
    String serviceId = viewModel!.services[index].id;
    String imageUrl = viewModel!.services[index].imageUrl;
    setState(() {
      viewModel!.services.removeAt(index);
    });
    firestoreService.deleteService(
        widget.loggedInUser.uid, serviceId, imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: userNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                      ),
                      if (userImageUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: ClipOval(
                            child: Image.network(
                              userImageUrl!,
                              width: 150.0,
                              height: 150.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text('Select Image'),
                      ),
                      TextField(
                        controller: userMessageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String? error = await viewModel!.updateUserProfile(
                            userNameController.text,
                            userMessageController.text,
                            userImageUrl!,
                          );

                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: viewModel!.services.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Image.network(
                              viewModel!.services[index].imageUrl,
                              width: 50,
                              height: 50,
                            ),
                            title: Text(viewModel!.services[index].type),
                            subtitle:
                                Text(viewModel!.services[index].description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(viewModel!.services[index].price
                                    .toString()),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    editService(index);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    deleteService(index);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: addService,
                        child: const Text('Add Service'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    viewModel!.removeListener(_updateState);
    super.dispose();
  }
}
