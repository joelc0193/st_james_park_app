import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class MapBoxControllerProvider with ChangeNotifier {
  MapboxMapController? _mapBoxController;
  StreamSubscription<DocumentSnapshot>? _userLocationSubscription;
  MapboxMapController? get mapBoxController => _mapBoxController;
  FirestoreService? firestoreService;
  final StreamController<Symbol> _symbolTapController =
      StreamController.broadcast();
  Stream<Symbol> get onSymbolTapped => _symbolTapController.stream;

  void _handleSymbolTapped(Symbol symbol) {
    _symbolTapController.add(symbol);
  }

  void setMapBoxController(MapboxMapController controller) {
    _mapBoxController = controller;
    _mapBoxController!.onSymbolTapped.add(_handleSymbolTapped);
  }

  Future<void> addImage(
    String name,
    Uint8List bytes, [
    bool sdf = false,
  ]) {
    return _mapBoxController!.addImage(name, bytes);
  }

  @override
  void dispose() {
    _mapBoxController?.onSymbolTapped.remove(_handleSymbolTapped);
    _symbolTapController.close();
    super.dispose();
  }

  Future<bool?> animateCamera(target, zoom, [double bearing = 30]) {
    return _mapBoxController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          bearing: bearing,
        ),
      ),
    );
  }

  Future<Symbol> addSymbol(SymbolOptions options,
      [Map<dynamic, dynamic>? data]) {
    return _mapBoxController!.addSymbol(options, data);
  }

  Future<void> clearSymbols() {
    if (mapBoxController != null) {
      return mapBoxController!.clearSymbols();
    } else {
      throw Exception('mapBoxController is null');
    }
  }

  Future<void> moveCameraToUser(String userId) async {
    // Cancel the previous subscription if it exists
    _userLocationSubscription?.cancel();

    // Subscribe to the user's location in Firestore
    _userLocationSubscription =
        firestoreService!.getUserLocationStream(userId).listen(
      (snapshot) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          GeoPoint location = data['location'];
          // Move the camera to the user's location
          animateCamera(
            LatLng(location.latitude, location.longitude),
            18.0,
          );
        } else {
          print('No data found in document: $snapshot');
        }
      },
      onError: (error) {
        print('Error listening to user location: $error');
      },
    );
  }
}
