import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:st_james_park_app/map_box.dart';
import 'package:st_james_park_app/mapbox_controller.dart';
import 'map_box.dart';

class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building _MapState...');

    return MapBox(
      requestLocationPermission: requestLocationPermission,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
