import 'package:flutter/material.dart';
import 'package:st_james_park_app/home_page.dart';
import 'package:st_james_park_app/visitors_page.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:st_james_park_app/settings_page.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'food_order_page.dart';
import 'map_page.dart';

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({Key? key}) : super(key: key);

  @override
  State<MainNavigationController> createState() =>
      _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  final List<Widget> _pages = [
    const HomePage(),
    const VisitorsPage(),
    const MapPage(),
    const FoodOrderPage(),
    const UserProfilePage(),
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('St James Park'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        type: BottomNavigationBarType.fixed,
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
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
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
