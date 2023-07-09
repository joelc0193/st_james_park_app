import 'package:flutter/material.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:st_james_park_app/user_upload_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return _buildContent(context, firestoreService);
  }

  Widget _buildContent(
      BuildContext context, FirestoreService firestoreService) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return Scrollbar(
          thumbVisibility: true,
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
                        _buildDataAnalysis(firestoreService),
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
          return const CircularProgressIndicator();
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
                  offset: const Offset(0, 1), // Shadow position
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                _buildRichText(),
                const SizedBox(height: 20),
                _buildImageOrText(imageUrl),
                const SizedBox(height: 10),
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
      text: const TextSpan(
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
      return const Text(
        'No Spotlight image',
        style: TextStyle(fontSize: 18),
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
          return const CircularProgressIndicator();
        } else {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            String? uploadedText = snapshot.data;
            return Text(
              uploadedText ?? 'No message uploaded',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            );
          }
        }
      },
    );
  }

  Widget _buildDataAnalysis(FirestoreService firestoreService) {
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
              const Text(
                '🌍 Total',
                style: TextStyle(
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
        const Divider(
          thickness: 1.0,
          height: 20.0,
        ),
        const Text(
          'Numbers too old?',
        ),
        Column(
          children: [
            TextButton(
              onPressed: () => _navigateToUserUploadPage(context),
              child: const Text(
                'Click here to update',
                style: TextStyle(
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

  Duration calculateTimeDifference(Timestamp lastUpdated) {
    return DateTime.now().difference(lastUpdated.toDate());
  }

  Widget _buildSpotlightText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: const <TextSpan>[
          TextSpan(text: 'And share something in our '),
          TextSpan(
            text: 'Spotlight',
            style: TextStyle(
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
          TextSpan(text: ' section'),
        ],
      ),
    );
  }

  void _navigateToUserUploadPage(BuildContext context) async {
    print('Navigating to user upload page');
    bool inPark = await _isInPark();
    print('In park: $inPark');
    if (inPark) {
      print('User is in the park');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserUploadPage()),
      );
    } else {
      print('User is not in the park');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not in the park'),
        ),
      );
    }
  }

  Future<bool> _isInPark() async {
    print('Checking if user is in the park'); // Print statement here

    PermissionStatus status = await Permission.location.status;
    if (!status.isGranted) {
      // We didn't have the location permission, request it.
      status = await Permission.location.request();
      if (!status.isGranted) {
        // The user denied the permission request.
        return false;
      }
    }
    Position position = await Geolocator.getCurrentPosition();
    double distanceInMeters = _calculateDistanceInMeters(
      parkLatitude,
      parkLongitude,
      position.latitude,
      position.longitude,
    );
    return true; //distanceInMeters < 174;
  }

  final double parkLatitude = 40.86512716517621;
  // Replace with the actual latitude
  final double parkLongitude = -73.89779740874255;
  // Replace with the actual longitude
  double _calculateDistanceInMeters(
      double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // 2 * R; R = 6371 km
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
