import 'package:geolocator/geolocator.dart';
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
  Future<bool> _isInPark() async {
    final double parkLatitude = 40.86512716517621;
    final double parkLongitude = -73.89779740874255;

    try {
      final position = await Geolocator.getCurrentPosition();
      double distanceInMeters = _calculateDistanceInMeters(
        parkLatitude,
        parkLongitude,
        position.latitude,
        position.longitude,
      );
      return distanceInMeters < 174;
    } catch (e) {
      throw Exception('Error getting location: $e');
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
                _buildRichText(),
                SizedBox(height: 20),
                _buildImageOrText(imageUrl),
                SizedBox(height: 10),
                _buildFutureText(firestoreService),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildRichText() {
    return RichText(
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
    );
  }

  Widget _buildImageOrText(String? imageUrl) {
    if (imageUrl != null) {
      return _buildImageContainer(imageUrl);
    } else {
      return Text(
        'No Spotlight image',
        style: TextStyle(color: Colors.white, fontSize: 18),
      );
    }
  }

  Widget _buildImageContainer(String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.yellow, width: 2), // Image border
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
      child: Container(
        height: 200, // adjust the height as needed
        width: 200, // adjust the width as needed
        decoration: BoxDecoration(
          border: Border.all(color: Colors.yellow, width: 2), // Image border
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover, // This will make the image cover the entire box
          ),
        ),
      ),
    );
  }

  Widget _buildFutureText(FirestoreService firestoreService) {
    return FutureBuilder<String?>(
      future: firestoreService.getUploadedText(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
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
          int sum =
              orderedKeys.fold(0, (prev, key) => prev + (data[key] as int));
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
      children: [
        for (int index = 0; index < orderedKeys.length; index++)
          _buildListTile(
              orderedKey: orderedKeys[index], data: data, emoji: emojis[index]),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: _buildNumberUpdateWidget(
              context: context, timeDifference: timeDifference),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String orderedKey,
    required Map<String, dynamic> data,
    required String emoji,
  }) {
    return ListTile(
      title: Text('$emoji $orderedKey'),
      trailing: Text(
        '${data[orderedKey]}',
        key: Key(orderedKey),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildNumberUpdateWidget({
    required BuildContext context,
    required Duration timeDifference,
  }) {
    return Column(
      children: [
        Text(
          formatTimeDifference(timeDifference),
          style: const TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 10),
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
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            _buildSpotlightText(context),
          ],
        ),
      ],
    );
  }

  Widget _buildSpotlightText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          const TextSpan(text: 'And share something in our '),
          TextSpan(
            text: 'Spotlight',
            style: const TextStyle(
              color: Colors.yellow,
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
          const TextSpan(text: ' section'),
        ],
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
