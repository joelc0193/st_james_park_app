import 'dart:html' as html;
import 'dart:html';
import 'dart:math' as math;
import 'dart:math' show cos, sqrt, asin, pi;
import 'package:flutter/gestures.dart';
import 'package:location_web/location_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:st_james_park_app/user_upload_page.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  final double parkLatitude =
      40.86512716517621; // Replace with the actual latitude
  final double parkLongitude =
      -73.89779740874255; // Replace with the actual longitude

  void getLocation() {
    if (html.window.navigator.geolocation != null) {
      html.window.navigator.geolocation
          .getCurrentPosition()
          .then((Geoposition position) {
        if (position.coords != null) {
          print(
              'Latitude: ${position.coords!.latitude}, Longitude: ${position.coords!.longitude}');
        } else {
          print('Unable to get location coordinates');
        }
      }).catchError((error) {
        print('Error getting location: $error');
      });
    } else {
      print('Geolocation is not available');
    }
  }

  Future<bool> _isInPark() async {
    final double parkLatitude =
        40.86512716517621; // Replace with the actual latitude
    final double parkLongitude =
        -73.89779740874255; // Replace with the actual longitude
    print(
        'html.window.navigator.geolocation: ${html.window.navigator.geolocation}');
    if (html.window.navigator.geolocation != null) {
      try {
        html.Geoposition position =
            await html.window.navigator.geolocation.getCurrentPosition();
        print('position.coords: ${position.coords}');
        if (position.coords != null) {
          double distanceInMeters = _calculateDistanceInMeters(
            parkLatitude,
            parkLongitude,
            position.coords!.latitude?.toDouble() ?? 0.0,
            position.coords!.longitude?.toDouble() ?? 0.0,
          );
          print(
              'position.coords!.latitude: ${position.coords!.latitude?.toDouble()}');
          print(
              'position.coords!.longitude: ${position.coords!.longitude?.toDouble()}');
          print('distanceInMeters: ${distanceInMeters}');
          return distanceInMeters < 174;
        } else {
          throw Exception('Unable to get location coordinates');
        }
      } catch (e) {
        throw Exception('Error getting location: $e');
      }
    } else {
      throw Exception('Geolocation is not available');
    }
  }

  double _calculateDistanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: _buildAppBar(context),
      body: _buildBody(context, firestoreService),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     if (await _isInPark()) {
      //       _navigateToUserUploadPage(context);
      //     } else {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         SnackBar(
      //           content: Text('You are not in the park'),
      //         ),
      //       );
      //     }
      //   },
      //   tooltip: 'Upload Image',
      //   child: Icon(Icons.add_a_photo),
      // ),
    );
  }

  void _navigateToUserUploadPage(BuildContext context) async {
    if (await _isInPark()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserUploadPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are not in the park'),
        ),
      );
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('St James Park People Counter'),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.admin_panel_settings),
          onPressed: () => _navigateToAdminPage(context),
        ),
      ],
    );
  }

  void _navigateToAdminPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  Widget _buildBody(BuildContext context, FirestoreService firestoreService) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return Scrollbar(
          isAlwaysShown: true,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        _buildHeader(firestoreService),
                        _buildContent(context, firestoreService),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // void _uploadImage(
  //     FirestoreService firestoreService, BuildContext context) async {
  //   final picker =
  //       ImagePicker(); // This will use image_picker_for_web on the web platform and image_picker on other platforms
  //   final pickedFile = await picker.getImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     final File imageFile = File(pickedFile.path);
  //     await firestoreService.uploadImage(imageFile);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Image uploaded successfully'),
  //       ),
  //     );
  //   } else {
  //     print('No image selected.');
  //   }
  // }

  Widget _buildHeader(FirestoreService firestoreService) {
    return FutureBuilder<String?>(
      future: firestoreService.getSpotlightImageUrl(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          String? imageUrl = snapshot.data;
          return Container(
            height: 350,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: Offset(0, 1), // Shadow position
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 25),
                RichText(
                  text: TextSpan(
                    text: 'Spotlight',
                    style: TextStyle(
                      color: Colors.yellow, // Changed color to yellow
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(2.0, 2.0),
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (imageUrl != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.yellow, width: 2), // Image border
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    child: Container(
                      height: 200, // adjust the height as needed
                      width: 200, // adjust the width as needed
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.yellow, width: 2), // Image border
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit
                              .cover, // This will make the image cover the entire box
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    'No Spotlight image',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                SizedBox(height: 10), // Space between image and text
                FutureBuilder<String?>(
                  future: firestoreService.getUploadedText(),
                  builder: (BuildContext context,
                      AsyncSnapshot<String?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        String? uploadedText = snapshot.data;
                        return Text(
                          uploadedText ?? 'No message uploaded',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        );
                      }
                    }
                  },
                )
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(
      BuildContext context, FirestoreService firestoreService) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.getAdminNumbers(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          List<String> orderedKeys = [
            'Basketball Courts',
            'Tennis Courts',
            'Soccer Field',
            'Playground',
            'Handball Courts',
            'Other'
          ];
          List<String> emojis = ['🏀', '🎾', '⚽', '🛝', '🔵', '🌳'];
          int sum = 0;
          for (var key in orderedKeys) {
            sum += data[key] as int;
          }
          return Column(
            children: [
              Text(
                '$sum',
                style: const TextStyle(
                  fontSize: 75,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                key: const Key('Total'),
              ),
              Text(
                '🌍 Total',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildListView(context, orderedKeys, data, emojis),
              )
            ],
          );
        } else {
          return const Center(child: Text('No data'));
        }
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<String> orderedKeys,
    Map<String, dynamic> data,
    List<String> emojis,
  ) {
    Duration timeDifference = calculateTimeDifference(data['Updated']);
    return Column(
      children: List.generate(
        orderedKeys.length * 2 + 1,
        (index) {
          if (index % 2 == 0 && index / 2 < orderedKeys.length) {
            var key = orderedKeys[index ~/ 2];
            var emoji = emojis[index ~/ 2];
            return ListTile(
              title: Text('$emoji $key'),
              trailing: Text(
                '${data[key]}',
                key: Key(key),
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins'),
              ),
            );
          } else if (index == orderedKeys.length * 2) {
            return Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Text(
                    formatTimeDifference(timeDifference),
                    style: const TextStyle(fontSize: 17),
                  ),
                  SizedBox(height: 10), // Add a bit of space
                  Divider(
                    color: Colors.white,
                    thickness: 1.0,
                    height: 20.0,
                  ),
                  Text(
                    'Numbers too old?',
                    style: TextStyle(color: Colors.white),
                  ),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => _navigateToUserUploadPage(context),
                        child: Text(
                          'Click here to update',
                          style: TextStyle(
                            color: Colors.blue, // Change the color as needed
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(text: 'And share something in our '),
                            TextSpan(
                              text: 'Spotlight',
                              style: TextStyle(
                                color: Colors.yellow, // Changed color to yellow
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 3.0,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(text: ' section'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Divider(
              color: Colors.white,
              thickness: 1.0,
              height: 20.0,
            );
          }
        },
      ),
    );
  }

  Duration calculateTimeDifference(Timestamp lastUpdated) {
    return DateTime.now().difference(lastUpdated.toDate());
  }

  String formatTimeDifference(Duration timeDifference) {
    if (timeDifference.inMinutes < 60) {
      return '⌚ Updated ${timeDifference.inMinutes} ${timeDifference.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else if (timeDifference.inHours < 2) {
      String hourUnit = timeDifference.inHours == 1 ? "hour" : "hours";
      String minuteUnit =
          timeDifference.inMinutes % 60 == 1 ? "minute" : "minutes";
      return '⌚ Updated ${timeDifference.inHours} $hourUnit and ${timeDifference.inMinutes % 60} $minuteUnit ago';
    } else {
      return '⌚ Updated ${timeDifference.inHours} ${timeDifference.inHours == 1 ? "hour" : "hours"} ago';
    }
  }
}
