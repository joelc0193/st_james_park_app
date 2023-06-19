import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin, pi;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/party_page.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:st_james_park_app/settings_page.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'package:st_james_park_app/user_upload_page.dart';
import 'package:provider/provider.dart';

import 'data_analysis_page.dart';
import 'map_page.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: _buildAppBar(context),
      body: _buildBody(context, firestoreService),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.party_mode),
            label: 'Party',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody(BuildContext context, FirestoreService firestoreService) {
    switch (_selectedIndex) {
      case 0:
        return _buildPeopleCounter(context, firestoreService);
      case 1:
        return PartyPage();
      case 2:
        return MapPage();
      case 3:
        return DataAnalysisPage();
      case 4:
        return UserProfilePage();
      default:
        return Text('Home Page');
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    if (_selectedIndex == 4) {
      return AppBar(
        title: const Text('User Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettingsPage(context),
          ),
        ],
      );
    } else {
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
  }

  void _navigateToSettingsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _navigateToAdminPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPage()),
    );
  }

  Widget _buildPeopleCounter(
      BuildContext context, FirestoreService firestoreService) {
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
}
