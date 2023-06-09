import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:st_james_park_app/home_page.dart';
import 'package:st_james_park_app/map_page.dart';
import 'package:st_james_park_app/services/mapbox_controller.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/market_page.dart';
import 'package:st_james_park_app/visitors_page.dart';
import 'package:st_james_park_app/settings_page.dart';
import 'package:st_james_park_app/user_profile_page.dart';
import 'music_page.dart';
import 'services/app_bar_manager.dart';

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
  late AuthService authService;
  late MapBoxControllerProvider mapBoxControllerProvider;
  late List<Widget> _pages;

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>()
  ];

  void _onLocationIconClicked(int index, String userId) {
    setState(() {
      _selectedIndex = index;
      mapBoxControllerProvider.moveCameraToUser(userId);
    });
  }

  List<Widget> _getPages() {
    return [
      const HomePage(),
      VisitorsPage(onLocationIconClicked: _onLocationIconClicked),
      MapPage(navigatorKey: _navigatorKeys[2]),
      const MusicPage(),
      MarketPage(onLocationIconClicked: _onLocationIconClicked),
      const UserProfilePage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.isUserLoggedIn.addListener(() {
      if (widget.isUserLoggedIn.value) {
        setState(() {
          _selectedIndex = 5; // Index of UserProfilePage
        });
      }
    });
    _pages = _getPages();
    mapBoxControllerProvider =
        Provider.of<MapBoxControllerProvider>(context, listen: false);
    authService = Provider.of<AuthService>(context, listen: false);
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

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => _pages[index],
          );
        },
      ),
    );
  }

  bool canPopVisitorsPage() {
    return _navigatorKeys[1].currentState?.canPop() ?? false;
  }

  bool canPopMapPage() {
    return _navigatorKeys[2].currentState?.canPop() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildOffstageNavigator(0),
          _buildOffstageNavigator(1),
          _buildOffstageNavigator(2),
          _buildOffstageNavigator(3),
          _buildOffstageNavigator(4),
          _buildOffstageNavigator(5),
        ],
      ),
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
            icon: Icon(Icons.music_note),
            label: 'Music',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Market',
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
    Provider.of<AppBarManager>(context);

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
    } else if (_selectedIndex == 1) {
      return AppBar(
        title: const Text('St James Park'),
        leading: canPopVisitorsPage()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _navigatorKeys[1].currentState?.pop();
                },
              )
            : null,
      );
    } else if (_selectedIndex == 2) {
      return AppBar(
        title: const Text('St James Park'),
        leading: canPopMapPage()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _navigatorKeys[2].currentState?.pop();
                },
              )
            : null,
      );
    } else {
      return AppBar(
        title: const Text('St James Park'),
      );
    }
  }

  void _navigateToSettingsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(authService),
      ),
    );
  }
}
