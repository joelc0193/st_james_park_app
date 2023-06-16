import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:image_picker/image_picker.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: _buildAppBar(context),
      body: _buildBody(context, firestoreService),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadImage(firestoreService, context),
        tooltip: 'Upload Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
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
    return Column(
      children: [
        _buildHeader(firestoreService),
        Expanded(child: _buildContent(context, firestoreService)),
      ],
    );
  }

  void _uploadImage(
      FirestoreService firestoreService, BuildContext context) async {
    final picker =
        ImagePicker(); // This will use image_picker_for_web on the web platform and image_picker on other platforms
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      await firestoreService.uploadImage(imageFile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded successfully'),
        ),
      );
    } else {
      print('No image selected.');
    }
  }

  Widget _buildHeader(FirestoreService firestoreService) {
    return FutureBuilder<String?>(
      future: firestoreService.getFeaturedImageUrl(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          String? imageUrl = snapshot.data;
          return Container(
            height: 200, // adjust the height as needed
            color: Colors.blue, // adjust the color as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Featured Member',
                    style: TextStyle(color: Colors.white, fontSize: 24)),
                if (imageUrl != null)
                  Image.network(imageUrl)
                else
                  Text('No featured image',
                      style: TextStyle(color: Colors.white)),
                Text('Some text about the featured member',
                    style: TextStyle(color: Colors.white)),
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
              Expanded(
                  child: _buildListView(context, orderedKeys, data, emojis)),
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
    return ListView.separated(
      itemCount: orderedKeys.length + 1,
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(color: Colors.white),
      itemBuilder: (context, index) {
        if (index < orderedKeys.length) {
          var key = orderedKeys[index];
          var emoji = emojis[index];
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
        } else {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Text(
                formatTimeDifference(timeDifference),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          );
        }
      },
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
