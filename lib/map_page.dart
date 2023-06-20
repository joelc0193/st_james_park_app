import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return MyMap();
  }
}

class MyMap extends StatefulWidget {
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  MapboxMapController? _controller;
  String? mapboxKey;

  void _onMapCreated(MapboxMapController controller) {
    if (!mounted) return;
    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getMapboxKey();
  }

  Future<void> getMapboxKey() async {
    const platform = const MethodChannel('com.gmail.joelc0193.st_james_park_app/key');
    try {
      final String result = await platform.invokeMethod('getMapboxKey');
      setState(() {
        mapboxKey = result;
      });
    } on PlatformException catch (e) {
      print("Failed to get Mapbox key: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mapboxKey == null) {
      return CircularProgressIndicator();
    } else {
      return MapboxMap(
        accessToken: mapboxKey,
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(40.86512716517621, -73.89779740874255),
          zoom: 17.8,
          bearing: 30,
        ),
        styleString: "mapbox://styles/joelc0193/clj4lm1j6000701qp6skd15yv",
      );
    }
  }
}
