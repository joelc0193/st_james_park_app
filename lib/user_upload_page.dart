import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

class UserUploadPage extends StatefulWidget {
  @override
  _UserUploadPageState createState() => _UserUploadPageState();
}

class _UserUploadPageState extends State<UserUploadPage> {
  final _formKey = GlobalKey<FormState>();
  PickedFile? _imageFile;
  late String _text;
  bool _isPrivacyPolicyAccepted = false;
  bool _isImageOrTextSubmitted = false;
  bool _isUserOldEnough = false;

  Map<String, TextEditingController> controllers = {};

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

  Future<void> captureMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _isImageOrTextSubmitted = true;
      });
    } else {
      setState(() {
        _isImageOrTextSubmitted = false;
      });
    }
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

            // Initialize controllers and defaultValues only if they are empty
            if (controllers.isEmpty) {
              controllers = {
                'Basketball Courts': TextEditingController(
                    text: data['Basketball Courts'].toString()),
                'Tennis Courts': TextEditingController(
                    text: data['Tennis Courts'].toString()),
                'Soccer Field': TextEditingController(
                    text: data['Soccer Field'].toString()),
                'Playground':
                    TextEditingController(text: data['Playground'].toString()),
                'Handball Courts': TextEditingController(
                    text: data['Handball Courts'].toString()),
                'Other': TextEditingController(text: data['Other'].toString()),
              };
              defaultValues = {
                'Basketball Courts': data['Basketball Courts'].toString(),
                'Tennis Courts': data['Tennis Courts'].toString(),
                'Soccer Field': data['Soccer Field'].toString(),
                'Playground': data['Playground'].toString(),
                'Handball Courts': data['Handball Courts'].toString(),
                'Other': data['Other'].toString(),
              };
            }

            return _buildForm(firestoreService);
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildForm(FirestoreService firestoreService) {
    return Container(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ...controllers.keys
                    .map((key) => _buildTextFormField(key))
                    .toList(),
                SizedBox(height: 10),
                _buildImageAndMessageFields(),
                SizedBox(height: 10),
                if (_isImageOrTextSubmitted) ...[
                  _buildPrivacyPolicyCheckbox(),
                  _buildAgeConfirmationCheckbox(),
                ],
                SizedBox(height: 10),
                _buildSubmitButton(firestoreService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String key) {
    return TextFormField(
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
    );
  }

  Widget _buildImageAndMessageFields() {
    return Column(
      children: [
        _buildOptionalText(),
        SizedBox(height: 10),
        _buildMediaWidget(),
        SizedBox(height: 10),
        _buildButtonsRow(),
        SizedBox(height: 10),
        _buildMessageField(),
      ],
    );
  }

  Widget _buildOptionalText() {
    return Text(
      'Optional: Add an image and a message',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMediaWidget() {
    if (_imageFile == null) {
      return const Center(child: Text('Your image here (Optional)'));
    } else {
      return Image.file(
        File(_imageFile!.path),
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text(
            _imageFile == null ? 'Take Picture (Optional)' : 'Change Picture',
          ),
          onPressed: captureMedia,
        ),
        if (_imageFile != null) ...[
          SizedBox(width: 10),
          ElevatedButton(
            child: Text('Clear Picture'),
            onPressed: () {
              setState(() {
                _imageFile = null;
                _isImageOrTextSubmitted = _text.isNotEmpty;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      onChanged: (value) {
        setState(() {
          _text = value;
          _isImageOrTextSubmitted = value.isNotEmpty || _imageFile != null;
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
    );
  }

  Widget _buildPrivacyPolicyCheckbox() {
    return Center(
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
    );
  }

  Widget _buildAgeConfirmationCheckbox() {
    return Center(
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
    );
  }

  Widget _buildSubmitButton(FirestoreService firestoreService) {
    return Center(
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
                    await firestoreService.updateAdminNumbers(numbers);
                    if (_imageFile != null) {
                      Uint8List imageBytes = await _imageFile!.readAsBytes();
                      // Now you can use imageBytes to upload the image to Firestore
                      await firestoreService.uploadMedia(imageBytes);
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
    );
  }
}
