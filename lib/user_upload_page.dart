import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class UserUploadPage extends StatefulWidget {
  @override
  _UserUploadPageState createState() => _UserUploadPageState();
}

class _UserUploadPageState extends State<UserUploadPage> {
  final _formKey = GlobalKey<FormState>();
  PickedFile? _image;
  late String _text;
  Map<String, TextEditingController> controllers = {
    'Basketball Courts': TextEditingController(),
    'Tennis Courts': TextEditingController(),
    'Soccer Field': TextEditingController(),
    'Playground': TextEditingController(),
    'Handball Courts': TextEditingController(),
    'Other': TextEditingController(),
  };
  Map<String, FocusNode> focusNodes = {
    'Basketball Courts': FocusNode(),
    'Tennis Courts': FocusNode(),
    'Soccer Field': FocusNode(),
    'Playground': FocusNode(),
    'Handball Courts': FocusNode(),
    'Other': FocusNode(),
  };
  Map<String, String> defaultValues = {}; // Map to store the default values

  @override
  void initState() {
    super.initState();
    focusNodes.forEach((key, focusNode) {
      focusNode.addListener(() {
        if (!focusNode.hasFocus && controllers[key]!.text.isEmpty) {
          controllers[key]!.text = defaultValues[key]!;
        }
      });
    });
  }

  Future<Uint8List> _readImageData(PickedFile image) async {
    final bytes = await image.readAsBytes();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('User Upload Page'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getAdminNumbers(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            controllers.forEach((key, controller) {
              defaultValues[key] =
                  data[key].toString(); // Store the default value
              controller.text = defaultValues[key]!;
            });
            return _buildForm(firestoreService);
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildForm(FirestoreService firestoreService) {
    Map<String, String> initialValues = {};

    return Container(
      color: Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              ...controllers.keys.map(
                (key) => TextFormField(
                  controller: controllers[key],
                  decoration: InputDecoration(
                    labelText: key,
                    hintText: controllers[key]!.text,
                    hintStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    return null;
                  },
                  onTap: () {
                    if (controllers[key]!.text == defaultValues[key]) {
                      controllers[key]!.clear();
                    }
                  },
                  focusNode: focusNodes[key],
                  onSaved: (value) {
                    setState(() {
                      controllers[key]!.text = value!;
                    });
                  },
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Optional: Add an image and a message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              SizedBox(height: 10),
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                  ),
                  child: _image == null
                      ? Center(child: Text('Your image here (Optional)'))
                      : FutureBuilder<Uint8List>(
                          future: _readImageData(_image!),
                          builder: (BuildContext context,
                              AsyncSnapshot<Uint8List> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text(_image == null
                        ? 'Pick Image (Optional)'
                        : 'Change Image'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile =
                          await picker.getImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() {
                          _image = pickedFile;
                        });
                      }
                    },
                  ),
                  if (_image != null) ...[
                    SizedBox(width: 10),
                    ElevatedButton(
                      child: Text('Clear Image'),
                      onPressed: () {
                        setState(() {
                          _image = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Add a message (Optional)',
                  hintText: 'Come to St. James!',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onSaved: (value) {
                  setState(() {
                    _text = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Map<String, int> numbers = {};
                      controllers.forEach((key, controller) {
                        numbers[key] = int.parse(controller.text);
                      });
                      try {
                        await firestoreService.updateAdminNumbers(numbers);
                        if (_image != null) {
                          await firestoreService.uploadImage(_image!);
                        }
                        await firestoreService.uploadText(_text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Upload successful'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Upload failed: $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
