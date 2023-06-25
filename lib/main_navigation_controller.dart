import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/home_page.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/visitors_page.dart';
import 'package:st_james_park_app/admin_page.dart';
import 'package:st_james_park_app/settings_page.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'food_order_page.dart';
import 'map_page.dart';

class MainNavigationController extends StatefulWidget {
  final ValueNotifier<bool> isUserLoggedIn;

  const MainNavigationController({
    Key? key,
    required this.isUserLoggedIn,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    widget.isUserLoggedIn.addListener(() {
      if (widget.isUserLoggedIn.value) {
        setState(() {
          _selectedIndex = 4; // Index of UserProfilePage
        });
      }
    });
  }

  @override
  void dispose() {
    widget.isUserLoggedIn.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
        // actions: <Widget>[
        //   IconButton(
        //     icon: const Icon(Icons.admin_panel_settings),
        //     onPressed: () => _navigateToAdminPage(context),
        //   ),
        // ],
      );
    }
  }

  void _navigateToSettingsPage(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(authService),
      ),
    );
  }

  // void _navigateToAdminPage(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const AdminPage()),
  //   );
  // }
}
