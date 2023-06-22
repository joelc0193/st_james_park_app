import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:mapbox_gl/mapbox_gl.dart';

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:mapbox_gl/mapbox_gl.dart';

class MapBox extends StatefulWidget {
  final Future<void> Function() requestLocationPermission;

  MapBox({required this.requestLocationPermission});

  @override
  _MapBoxState createState() => _MapBoxState();
}

class _MapBoxState extends State<MapBox> {
  MapboxMapController? mapController;
  final double parkLatitude = 40.86512716517621;
  final double parkLongitude = -73.89779740874255;
  Symbol? userLocationSymbol;
  StreamSubscription<Position>? positionStream;
  Position? lastPosition;

  @override
  void initState() {
    super.initState();
    widget.requestLocationPermission().then((_) {
      Timer.periodic(Duration(seconds: 1), (Timer t) async {
        Position position = await Geolocator.getCurrentPosition();
        _updateUserLocation(position);
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _updateUserLocation(Position position) async {
    print('Updating user location...');
    if (await _isInPark(position)) {
      print('User is in the park');
      if (lastPosition == null ||
          _calculateDistanceInMeters(
                  lastPosition!.latitude,
                  lastPosition!.longitude,
                  position.latitude,
                  position.longitude) >
              5) {
        // Only update the symbol if the position has changed significantly
        lastPosition = position;
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            17.0,
          ),
        );
        if (userLocationSymbol == null) {
          userLocationSymbol = await mapController?.addSymbol(
            SymbolOptions(
              geometry: LatLng(position.latitude, position.longitude),
              iconImage: 'marker-15',
              iconColor: '#ff0000',
            ),
          );
        } else {
          await mapController?.updateSymbol(
            userLocationSymbol!,
            SymbolOptions(
              geometry: LatLng(position.latitude, position.longitude),
            ),
          );
        }
      }
    } else {
      print('User is not in the park');
      if (userLocationSymbol != null) {
        await mapController?.removeSymbol(userLocationSymbol!);
        userLocationSymbol = null;
      }
    }
  }

  Future<String> getMapboxAccessToken() async {
    print('Getting Mapbox access token...');
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      String accessToken = config['mapboxAccessToken'] as String;
      print('Got token');
      return accessToken;
    } catch (e) {
      print('Error getting Mapbox access token: $e');
      throw e;
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

  Future<bool> _isInPark(Position position) async {
    double distanceInMeters = _calculateDistanceInMeters(
      parkLatitude,
      parkLongitude,
      position.latitude,
      position.longitude,
    );
    return distanceInMeters < 174;
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getMapboxAccessToken(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return Text('Mapbox access token is null');
          } else {
            return MapboxMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(parkLatitude, parkLongitude),
                bearing: 5,
                zoom: 17,
              ),
              accessToken: snapshot.data,
              onMapCreated: _onMapCreated,
            );
          }
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapState();
}

class _MapState extends State<MapPage> {
  @override
  @override
  void initState() {
    super.initState();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }

    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        var backgroundStatus = await Permission.locationAlways.status;
        if (!backgroundStatus.isGranted) {
          await Permission.locationAlways.request();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building _MapState...');
    return MapBox(requestLocationPermission: requestLocationPermission);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
