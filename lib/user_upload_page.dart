import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
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
  String? _imageDataUrl; // Add this line
  late String _text;
  bool _isPrivacyPolicyAccepted = false;
  bool _isImageOrTextSubmitted = false;
  bool _isUserOldEnough = false; // Add this line

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

  void _launchURL() async {
    const url =
        'https://docs.google.com/document/d/e/2PACX-1vQoIiIH_3_pA3XXDmA7EENTL-ZUH41hKkVcVraaVucWzcW9ybLloUnyuAe_JwfEMJyh1G3ez0cHemGO/pub';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void captureImage() {
    html.InputElement input =
        html.document.createElement('input') as html.InputElement;
    input
      ..type = 'file'
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment'); // indicates capture from camera

    input.onChange.listen((e) {
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          // You can use reader.result as the image data url
          print(reader.result);
          // Convert the data URL to a PickedFile and set _image
          setState(() {
            _imageDataUrl = reader.result.toString();
            _isImageOrTextSubmitted = true;
          });
        });
      } else {
        setState(() {
          _isImageOrTextSubmitted = false;
        });
      }
    });

    input.click();
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
                  child: _imageDataUrl == null
                      ? Center(child: Text('Your image here (Optional)'))
                      : Image.network(
                          _imageDataUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text(_imageDataUrl == null
                        ? 'Take Picture (Optional)'
                        : 'Change Picture'),
                    onPressed: captureImage,
                  ),
                  if (_imageDataUrl != null) ...[
                    SizedBox(width: 10),
                    ElevatedButton(
                      child: Text('Clear Image'),
                      onPressed: () {
                        setState(() {
                          _imageDataUrl = null;
                          _isImageOrTextSubmitted = _text.isNotEmpty;
                        });
                      },
                    ),
                  ],
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _text = value;
                    _isImageOrTextSubmitted =
                        value.isNotEmpty || _imageDataUrl != null;
                  });
                },
                maxLength: 250,
                buildCounter: (BuildContext context,
                    {required int currentLength,
                    required bool isFocused,
                    int? maxLength}) {
                  return Text(
                    '${maxLength! - currentLength} characters left',
                    style: TextStyle(color: Colors.white),
                  );
                },
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
              if (_isImageOrTextSubmitted) ...[
                Center(
                  child: Container(
                    width: 450, // Adjust this value as needed
                    child: CheckboxListTile(
                      title: Text(
                        "I accept the Terms of Service and Privacy Policy",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isPrivacyPolicyAccepted,
                      onChanged: (newValue) {
                        setState(() {
                          _isPrivacyPolicyAccepted = newValue!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 450, // Adjust this value as needed
                    child: CheckboxListTile(
                      title: Text(
                        "I confirm that I am 13 years old or older",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isUserOldEnough,
                      onChanged: (newValue) {
                        setState(() {
                          _isUserOldEnough = newValue!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  child: Text('Submit'),
                  onPressed: (!_isImageOrTextSubmitted ||
                          (_isPrivacyPolicyAccepted && _isUserOldEnough))
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            Map<String, int> numbers = {};
                            controllers.forEach((key, controller) {
                              numbers[key] = int.parse(controller.text);
                            });
                            try {
                              await firestoreService
                                  .updateAdminNumbers(numbers);
                              if (_imageDataUrl != null) {
                                await firestoreService.uploadImage(
                                    _imageDataUrl); // Update this line
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
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
