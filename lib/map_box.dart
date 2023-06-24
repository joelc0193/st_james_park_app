import 'dart:async';
import 'dart:convert';

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

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
  Position? lastPosition;
  List<Symbol> userSymbols = [];
  bool isFollowingUser = false;
  Timer? locationUpdateTimer;
  StreamSubscription<QuerySnapshot>? firestoreSubscription;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    widget.requestLocationPermission().then((_) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5, // Set distance filter to 5 meters
        ),
      ).listen((Position position) {
        _updateUserLocation(position);
      });
    });

    // Get FirestoreService from the context
    FirestoreService firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    firestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateUserSymbols(List<DocumentSnapshot> docs) async {
    print(
        'Starting to update user symbols...'); // Print when starting to update symbols
    print(
        'Number of documents received: ${docs.length}'); // Print the number of documents

    // Remove all existing symbols
    mapController!.clearSymbols();
    userSymbols.clear();

    // Add new symbols
    int addedSymbolsCount = 0;
    for (var doc in docs) {
      try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        print('Document data: $data'); // Print the data of each document
        if (data != null) {
          GeoPoint location = data['location'];
          LatLng latLngLocation = LatLng(location.latitude, location.longitude);
          print(
              'LatLng location: $latLngLocation'); // Print the LatLng location
          SymbolOptions symbolOptions = SymbolOptions(
            geometry: latLngLocation,
            iconImage: 'marker-15',
          );
          print('SymbolOptions: $symbolOptions'); // Print the SymbolOptions
          if (mapController != null) {
            Symbol? symbol;
            symbol = await mapController?.addSymbol(symbolOptions);
            if (symbol != null) {
              userSymbols.add(symbol);
              addedSymbolsCount++;
              print(
                  'Added symbol for user at location: $location'); // Print after adding each symbol
            } else {
              print('Failed to add symbol'); // Print if failed to add symbol
            }
          } else {
            print('mapController is null'); // Print if mapController is null
          }
        } else {
          print('No data found in document: $doc'); // Print if no data is found
        }
      } catch (e) {
        print(
            'Exception thrown while updating symbols: $e'); // Print any exceptions that are thrown
      }
    }

    print(
        'Finished updating user symbols. Added $addedSymbolsCount new symbols.'); // Print after finishing updating symbols
  }

  Future<void> _updateUserLocation(Position position) async {
    print('Updating user location...');
    bool isInPark = await _isInPark(position);
    GeoPoint location = GeoPoint(position.latitude, position.longitude);

    // Get FirestoreService and AuthService from the context
    FirestoreService firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    AuthService authService = Provider.of<AuthService>(context, listen: false);

    // Get the user ID
    String? userId = authService.getCurrentUserId();
    if (userId != null) {
      await firestoreService.updateUserLocation(userId, location, isInPark);
    }
    if (isFollowingUser) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          18.0,
        ),
      );
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

  void _onMapCreated(MapboxMapController controller) async {
    mapController = controller;

    // Get FirestoreService from the context
    FirestoreService firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    firestoreSubscription = firestoreService.getUsersInPark().listen(
      (snapshot) {
        print(
            'Received new snapshot: $snapshot'); // Print when a new snapshot is received
        _updateUserSymbols(snapshot.docs);
      },
      onError: (error) {
        print(
            'Error listening to getUsersInPark: $error'); // Print any errors that occur when listening to the Stream
      },
    );
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
            print('in build\'s FutureBuilder');
            return Stack(
              children: [
                MapboxMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(parkLatitude, parkLongitude),
                    bearing: 30,
                    zoom: 17,
                  ),
                  accessToken: snapshot.data,
                  onMapCreated: _onMapCreated,
                ),
                StatefulBuilder(
                  builder: (context, setState) => Positioned(
                    right: 25,
                    bottom: 25,
                    child: FollowUserButton(
                      onPressed: () async {
                        isFollowingUser = !isFollowingUser;
                        if (!isFollowingUser) {
                          // If the camera is now not following the user, move it back to its initial position
                          mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(parkLatitude, parkLongitude),
                                zoom: 17.0,
                                bearing: 30,
                              ),
                            ),
                          );
                        } else {
                          // If the camera is now following the user, move it to the user's current location
                          Position position =
                              await Geolocator.getCurrentPosition();
                          mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(position.latitude, position.longitude),
                              18.0,
                            ),
                          );
                        }
                        // Call setState in the MapBox widget to update the UI
                        setState(() {});
                      },
                      isFollowingUser: isFollowingUser,
                    ),
                  ),
                ),
              ],
            );
          }
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class FollowUserButton extends StatelessWidget {
  final Function onPressed;
  final bool isFollowingUser;

  FollowUserButton({required this.onPressed, required this.isFollowingUser});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => onPressed(),
      child: Icon(
          isFollowingUser ? Icons.location_disabled : Icons.location_searching),
    );
  }
}
