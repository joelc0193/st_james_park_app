import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/user_upload_page.dart';
import 'package:provider/provider.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({Key? key}) : super(key: key);

  @override
  _DataAnalysisPageState createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return _buildContent(context, firestoreService);
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

  Duration calculateTimeDifference(Timestamp lastUpdated) {
    return DateTime.now().difference(lastUpdated.toDate());
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

  void _navigateToUserUploadPage(BuildContext context) async {
    print('Navigating to user upload page');
    bool inPark = await _isInPark();
    print('In park: $inPark');
    if (inPark) {
      print('User is in the park');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserUploadPage()),
      );
    } else {
      print('User is not in the park');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
