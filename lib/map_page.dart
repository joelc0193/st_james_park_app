import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:st_james_park_app/services/mapbox_controller.dart';
import 'package:st_james_park_app/other_user_profile_page.dart';
import 'package:st_james_park_app/services/app_bar_manager.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/user_data.dart';

class MapPage extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MapPage({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();

  static _MapPageState of(BuildContext context) {
    return context.findAncestorStateOfType<_MapPageState>()!;
  }
}

class _MapPageState extends State<MapPage> {
  late MapBoxControllerProvider? mapBoxControllerProvider;
  final double parkLatitude = 40.86512716517621;
  final double parkLongitude = -73.89779740874255;
  Symbol? userLocationSymbol;
  Position? lastPosition;
  List<Symbol> userSymbols = [];
  bool isFollowingUser = false;
  Timer? locationUpdateTimer;
  StreamSubscription<QuerySnapshot>? firestoreSubscription;
  StreamSubscription<Position>? _positionStream;
  late FirestoreService firestoreService;
  late AuthService authService;
  StreamSubscription<DocumentSnapshot>? _userLocationSubscription;
  bool areDialogBoxesVisible = true;
  List<DocumentSnapshot> docs = [];
  StreamSubscription<Symbol>? _symbolTapSubscription;

  @override
  void initState() {
    super.initState();
    requestLocationPermission().then((_) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5, // Set distance filter to 5 meters
        ),
      ).listen((Position position) {
        _updateUserLocation(position);
      });
    });

    firestoreService = Provider.of<FirestoreService>(context, listen: false);
    authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    firestoreSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _symbolTapSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cleanCache(Directory cacheDir, Set<String> usedImages) async {
    try {
      // Get all files in the cache directory
      List<FileSystemEntity> cacheFiles = cacheDir.listSync();

      for (FileSystemEntity entity in cacheFiles) {
        if (entity is File) {
          // Get the filename of the file
          String filename = path.basename(entity.path);
          String filenameWithoutExtension = filename.replaceAll('.png', '');

          // If the file is not in the usedImages Set, delete it
          if (!usedImages.contains(filenameWithoutExtension)) {
            // Delete the file
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Exception thrown while cleaning cache: $e');
    }
  }

  Future<void> _updateUserSymbols() async {
    // Get the directory to store the cached images
    Directory cacheDir = await getTemporaryDirectory();

    // Create a Set to store the filenames of the used images
    Set<String> usedImages = {};

    // Remove all existing symbols
    if (userSymbols.isNotEmpty) {
      userSymbols.clear();
      mapBoxControllerProvider?.clearSymbols();
    }

    // Add new symbols
    int addedSymbolsCount = 0;
    for (var doc in docs) {
      try {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          GeoPoint location = data['location'];
          LatLng latLngLocation = LatLng(location.latitude, location.longitude);

          // Download the image and convert it to a bitmap
          String imageUrl = data['imageUrl'];
          String iconId = 'icon-${doc.id}';

          // Add the filename of the used image to the Set
          usedImages.add(iconId);

          // Check if a cached image exists
          File cachedImageFile = File('${cacheDir.path}/$iconId.png');
          Uint8List bytes;
          if (await cachedImageFile.exists()) {
            // If a cached image exists, load it
            bytes = await cachedImageFile.readAsBytes();
            print('Got image from cache');
          } else {
            // If no cached image exists, download the image, process it, and cache it
            File file = await DefaultCacheManager().getSingleFile(imageUrl);
            bytes = await makeCircularImage(file.path);
            await cachedImageFile.writeAsBytes(bytes);
          }

          // Add the bitmap to the map as an icon
          await mapBoxControllerProvider!.addImage(iconId, bytes);

          SymbolOptions symbolOptions = SymbolOptions(
            geometry: latLngLocation,
            iconImage: iconId,
            textField: areDialogBoxesVisible ? data['name'] : '',
            textOffset: const Offset(0, -1.5),
          );

          if (mapBoxControllerProvider != null) {
            Symbol symbol = await mapBoxControllerProvider!.addSymbol(
              symbolOptions,
              {'userId': doc.id},
            );
            userSymbols.add(symbol);
            addedSymbolsCount++;
          }
        }
      } catch (e) {
        print('Exception thrown while updating symbols: $e');
      }
    }
    // Clean the cache
    await _cleanCache(cacheDir, usedImages);
  }

  Future<void> _updateUserLocation(Position position) async {
    print('Updating user location...');
    bool isInPark = await _isInPark(position);
    GeoPoint location = GeoPoint(position.latitude, position.longitude);

    // Get the user ID
    String? userId = authService.getCurrentUserId();
    if (userId != null) {
      await firestoreService.updateUserLocation(userId, location, isInPark);
    }

    if (isFollowingUser) {
      MapBoxControllerProvider? mapBoxControllerProvider =
          Provider.of<MapBoxControllerProvider>(context, listen: false);
      mapBoxControllerProvider.animateCamera(
        LatLng(position.latitude, position.longitude),
        18.0,
      );
    }
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
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
      rethrow;
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

  void _onSymbolTapped(Symbol symbol) async {
    // Fetch the user's data from Firestore
    String? userId = symbol.data?['userId'] as String?;
    UserData? userData =
        userId != null ? await firestoreService.getUserData(userId) : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'User Profile Preview',
            style: TextStyle(color: Colors.blue, fontSize: 20),
          ),
          content: userData == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Welcome, ${userData.name}!'),
                    ),
                    userData.imageUrl != null
                        ? ClipOval(
                            child: SizedBox(
                              width: 150, // Set width
                              height: 150, // Set height
                              child: Image.network(
                                userData.imageUrl,
                                fit: BoxFit
                                    .cover, // Use BoxFit.cover to maintain the aspect ratio
                              ),
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(userData.message ?? 'Not available'),
                    ),
                  ],
                ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Go to profile',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                // Navigate to the OtherUserProfilePage
                _navigateToProfile(context, userId!);
              },
            ),
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    final appBarManager = Provider.of<AppBarManager>(context, listen: false);
    appBarManager.show();
    widget.navigatorKey.currentState!
        .push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfilePage(userId: userId),
      ),
    )
        .then((_) {
      // Hide the back button when the user navigates back
      appBarManager.hide();
    });
  }

  void _onMapCreated(MapboxMapController controller) async {
    mapBoxControllerProvider =
        Provider.of<MapBoxControllerProvider>(context, listen: false)
          ..setMapBoxController(controller);

    controller.onSymbolTapped.add(_onSymbolTapped); // Add this line

    firestoreSubscription = firestoreService.getUsersInPark().listen(
      (snapshot) {
        print(
            'Received new snapshot: $snapshot'); // Print when a new snapshot is received
        docs = snapshot.docs; // Store the list of documents
        _updateUserSymbols();
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
            return const Text('Mapbox access token is null');
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
                    child: Column(
                      children: [
                        FollowUserButton(
                          heroTag: 'fab1',
                          onPressed: () async {
                            isFollowingUser = !isFollowingUser;
                            if (!isFollowingUser) {
                              // If the camera is now not following the user, move it back to its initial position
                              mapBoxControllerProvider?.animateCamera(
                                LatLng(parkLatitude, parkLongitude),
                                17.0,
                              );
                              // Cancel the user location subscription
                              _userLocationSubscription?.cancel();
                            } else {
                              // If the camera is now following the user, move it to the user's current location
                              String? userId = authService.getCurrentUserId();
                              if (userId != null) {
                                mapBoxControllerProvider
                                    ?.moveCameraToUser(userId);
                              }
                            }
                            // Call setState in the MapBox widget to update the UI
                            setState(() {});
                          },
                          isFollowingUser: isFollowingUser,
                        ),
                        const SizedBox(
                            height: 10), // Add some space between the buttons
                        ToggleDialogBoxesButton(
                          heroTag: 'fab2',
                          onPressed: () {
                            // Toggle the visibility of the dialog boxes
                            areDialogBoxesVisible = !areDialogBoxesVisible;
                            // Update the symbols on the map
                            _updateUserSymbols();
                            // Call setState here
                            setState(() {});
                          },
                          areDialogBoxesVisible: areDialogBoxesVisible,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class FollowUserButton extends StatelessWidget {
  final String heroTag;
  final Function onPressed;
  final bool isFollowingUser;

  const FollowUserButton(
      {super.key,
      required this.heroTag,
      required this.onPressed,
      required this.isFollowingUser});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => onPressed(),
      child: Icon(
          isFollowingUser ? Icons.location_disabled : Icons.location_searching),
    );
  }
}

class ToggleDialogBoxesButton extends StatelessWidget {
  final String heroTag;
  final Function onPressed;
  final bool areDialogBoxesVisible;

  const ToggleDialogBoxesButton(
      {super.key,
      required this.heroTag,
      required this.onPressed,
      required this.areDialogBoxesVisible});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => onPressed(),
      child:
          Icon(areDialogBoxesVisible ? Icons.visibility_off : Icons.visibility),
    );
  }
}

Future<Uint8List> makeCircularImage(String path, {int size = 50}) async {
  final originalFile = File(path);
  img.Image? originalImage = img.decodeImage(await originalFile.readAsBytes());

  if (originalImage != null) {
    // Resize the image to a square with the dimension of the smaller original dimension
    int minValue = math.min(originalImage.width, originalImage.height);
    img.Image resizedImage =
        img.copyResize(originalImage, width: minValue, height: minValue);

    // Create a new image with the same dimension and a transparent background
    img.Image circleImage = img.Image(minValue, minValue);

    // Calculate the center of the square
    int centerX = resizedImage.width ~/ 2;
    int centerY = resizedImage.height ~/ 2;

    // Calculate the radius of the circle
    int radius = minValue ~/ 2;

    // Get each pixel of the square image and if it's outside the circle make it transparent
    for (int x = 0; x < resizedImage.width; x++) {
      for (int y = 0; y < resizedImage.height; y++) {
        // Calculate the distance between the center of the square and the current pixel
        int dx = centerX - x;
        int dy = centerY - y;
        double distance = math.sqrt(dx * dx + dy * dy);

        // If the distance is less than the radius, it's inside the circle
        if (distance <= radius) {
          // Get the color of the pixel
          int color = resizedImage.getPixel(x, y);

          // Set the color of the pixel in the new image
          circleImage.setPixel(x, y, color);
        }
      }
    }

    // Resize the circular image to the desired size
    img.Image finalImage =
        img.copyResize(circleImage, width: size, height: size);

    // Encode the image to PNG
    List<int> png = img.encodePng(finalImage);

    return Uint8List.fromList(png);
  } else {
    throw Exception('Failed to load image');
  }
}
