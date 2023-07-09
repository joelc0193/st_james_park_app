import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(ParkMessageApp());
}

class ParkMessageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Park Message App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MapScreen(),
    );
  }
}