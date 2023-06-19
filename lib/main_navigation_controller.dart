import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin, pi;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:st_james_park_app/home_page.dart';
import 'package:st_james_park_app/visitors_page.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:st_james_park_app/settings_page.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'package:st_james_park_app/user_upload_page.dart';
import 'package:provider/provider.dart';
import 'food_order_page.dart';
import 'map_page.dart';

class MainNavigationController extends StatefulWidget {
  MainNavigationController({Key? key}) : super(key: key);

  @override
  State<MainNavigationController> createState() =>
      _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
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
            icon: Icon(Icons.people),
            label: 'Visitors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Food',
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
        return HomePage();
      case 1:
        return VisitorsPage();
      case 2:
        return MapPage();
      case 3:
        return FoodOrderPage();
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
        title: const Text('St James Park'),
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
}
