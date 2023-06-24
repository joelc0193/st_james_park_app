import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:st_james_park_app/map_box.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
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