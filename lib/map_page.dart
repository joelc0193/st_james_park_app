import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapState();
}

class _MapState extends State<MapPage> {
  MapboxMapController? _controller;
  LatLng? userLocation;
  Symbol? userSymbol;

  void _onMapCreated(MapboxMapController controller) {
    if (!mounted) return;
    _controller = controller;
    _updateUserLocation();
  }

  Future<String> getMapboxAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/config.json');
    final config = jsonDecode(jsonString) as Map<String, dynamic>;
    return config['mapboxAccessToken'] as String;
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

  final double parkLatitude = 40.86512716517621;
  final double parkLongitude = -73.89779740874255;
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

  Future<void> _updateUserLocation() async {
    print('Update User Location Function Called'); // Print statement here
    LocationPermission permission;

    // Test if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position.
      print('Location services are disabled.'); // Print statement here
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    print('Permission checked: $permission'); // Print statement here
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('Permission requested: $permission'); // Print statement here
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        print('Location permissions are denied'); // Print statement here
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(
          'Location permissions are permanently denied'); // Print statement here
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Geolocator.getPositionStream().listen((Position position) async {
      print(
          'Position Stream Triggered: ${position.toString()}'); // print position stream
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      print(
          'Current LatLng: ${currentLatLng.toString()}'); // print current LatLng
      if (await _isInPark()) {
        print('Is In Park: true'); // print if in park
        if (_controller != null) {
          print('Controller is not null'); // print if controller is not null
          Symbol? newSymbol = await _controller?.addSymbol(SymbolOptions(
            geometry: currentLatLng,
            iconImage: "assetImage",
            iconSize: 1.5,
          ));
          print('New Symbol: ${newSymbol.toString()}'); // print new symbol
          setState(() {
            userLocation = currentLatLng;
            print(
                'User Location: ${userLocation.toString()}'); // print user location
            if (userSymbol != null) {
              _controller?.removeSymbol(userSymbol!);
              print('User Symbol Removed'); // print if user symbol is removed
            }
            userSymbol = newSymbol;
            print('User Symbol: ${userSymbol.toString()}'); // print user symbol
          });
        } else {
          print('Controller is null'); // print if controller is null
        }
      } else {
        print('Is In Park: false'); // print if not in park
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getMapboxAccessToken(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show a loading spinner while waiting
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return MapboxMap(
            accessToken: snapshot.data,
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(40.86512716517621, -73.89779740874255),
              zoom: 17,
              bearing: 30,
            ),
            styleString:
                "mapbox://styles/joelc0193/clj4lm1j6000701qp6skd15yv", // your Mapbox style URL
          );
        }
      },
    );
  }
}
