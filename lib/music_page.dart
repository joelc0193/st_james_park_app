import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({Key? key}) : super(key: key);

  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  bool _hasNominated = false;
  bool _connected = false;
  List<dynamic> _searchResults = [];
  TextEditingController _searchController = TextEditingController();
  String? _nominatedSong;
  FirestoreService _firestoreService =
      FirestoreService(firestore: FirebaseFirestore.instance);
  AuthService _authService = AuthService(auth: FirebaseAuth.instance);
  Timer? _songTimer;
  // Add a ValueNotifier for the countdown timer
  ValueNotifier<String> _countdownTimer = ValueNotifier<String>("");
  ValueNotifier<int> _songDuration = ValueNotifier<int>(0);
  Timer?
      _countdownTimerInstance; // Add this line at the top of your _MusicPageState class
  bool _isSongPlaying = false;
  List<String> _votedSongs = [];
  String _status = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterAppAuth appAuth = FlutterAppAuth();
  final MethodChannel _channel = const MethodChannel(
      'com.gmail.joelc0193.st_james_park_app/spotify_callback');
  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticating = false;
  bool _isFirestoreListenerSetUp = false;

  Future<void> getAccessToken(String accessToken,
      [String? refreshToken]) async {
    _accessToken = accessToken;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
    setState(() => {});
  }

  @override
  void initState() {
    super.initState();

    // Start the authentication process only if the current user's email is user1@example.com
    _authService.userState.listen((User? user) {
      if (user != null && user.email == 'user1@example.com') {
        initiateSpotifyAuthentication();
      }

      // Retrieve the hasNominated flag for the current user
      String? userId = _authService.getCurrentUserId();
      if (userId != null && !_isFirestoreListenerSetUp) {
        _isFirestoreListenerSetUp = true;
        _firestoreService.firestore
            .collection('users')
            .doc(userId)
            .snapshots()
            .listen((userSnapshot) {
          _hasNominated =
              (userSnapshot.data() as Map<String, dynamic>)?['hasNominated'] ??
                  false;
          _votedSongs = List<String>.from(
              (userSnapshot.data() as Map<String, dynamic>)?['votedSongs'] ??
                  []);
          setState(() {}); // Update the state to reflect the changes
        });
      }
    });

    // Listen for changes to the song duration in Firestore
    _firestoreService.firestore
        .collection('current_song')
        .doc('duration')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        // Get the song duration from the snapshot
        int duration = snapshot.data()?['duration'] ?? 0;

        // Start the countdown timer
        startCountdownTimer(duration);
      }
    });

    // Listen for changes in the nominated_songs collection
    _firestoreService.firestore
        .collection('nominated_songs')
        .snapshots()
        .listen((snapshot) async {
      // Filter docChanges to only include added documents
      final addedDocs = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added);

      // Check if there is 1 added song now and the player is paused
      if (addedDocs.length == 1 && !_isSongPlaying) {
        // Get the current user
        User? user = _authService.getCurrentUser();
        // If the current user is user1, call playNextSong
        if (user != null && user.email == 'user1@example.com') {
          await playNextSong();
        }
      }
    });
  }

  Future<void> playNextSong() async {
    try {
      if (_accessToken == null) {
        throw Exception('Access token not found');
      }

      try {
        await pauseCurrentSong(_accessToken!);
      } catch (e) {
        print(e.toString());
      }
      await waitForSongToPause(_accessToken!);

      String songUri = await getNextSongUri();
      await startNextSong(_accessToken!, songUri);

      // Update the song duration after the new song has started
      await updateSongDuration(_accessToken!);

      await clearNominations();
      await _firestoreService.firestore
          .collection('current_song')
          .doc('duration')
          .delete();
    } catch (e) {
      print('error playing song: $e');
      if (e is Exception && e.toString() == 'Exception: No songs nominated') {
        // No need to pause the current song again here
      } else if (e is Exception && e.toString().contains('403')) {
        // If you get a 403 error, refresh the access token
        try {
          await refreshAccessToken();
          playNextSong();
        } catch (refreshError) {
          print('Error refreshing access token: $refreshError');
        }
      } else {
        print('Unexpected error: $e');
      }
    }
  }

  Future<void> refreshAccessToken() async {
    try {
      final config = await _getConfig();
      final String clientId = config['CLIENT_ID'].toString();
      final String clientSecret = config['CLIENT_SECRET'].toString();
      final String credentials = '$clientId:$clientSecret';
      final String basicCredentials = base64Encode(utf8.encode(credentials));

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $basicCredentials',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> tokenResponse = jsonDecode(response.body);
        final String newAccessToken = tokenResponse['access_token'];
        // Store the new access token
        _accessToken = newAccessToken;
      } else {
        print(
            'Failed to refresh access token. Status code: ${response.statusCode}, Reason: ${response.reasonPhrase}, Response body: ${response.body}');
        if (response.statusCode == 400) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['error'] == 'invalid_grant') {
            // The refresh token has been revoked. Start the process to obtain a new refresh token.
            initiateSpotifyAuthentication();
          }
        }
      }
    } catch (e) {
      print('Error refreshing access token: $e');
    }
  }

  Future<String> getNextSongUri() async {
    // Get the URI of the song with the most votes
    String songUri = await _firestoreService.getSongWithMostVotes();

    // Get the details of the song with the most votes
    DocumentSnapshot songSnapshot = await _firestoreService.firestore
        .collection('nominated_songs')
        .doc(songUri)
        .get();
    Map<String, dynamic> songDetails =
        songSnapshot.data() as Map<String, dynamic>;

    // Store the details of the song with the most votes
    await _firestoreService.storeMostVotedSongDetails(songDetails);

    return songUri;
  }

  Future<void> waitForSongToStart(String accessToken) async {
    Map<String, dynamic>? playerState;
    do {
      await Future.delayed(Duration(milliseconds: 500)); // Wait for 1 second
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      playerState = jsonDecode(response.body);
    } while (playerState?['item'] == null);
  }

  Future<void> clearNominations() async {
    await _firestoreService.deleteAllNominatedSongsExceptSecondHighest();
    QuerySnapshot userSnapshot =
        await _firestoreService.firestore.collection('users').get();
    for (var doc in userSnapshot.docs) {
      await doc.reference.update({'votedSongs': [], 'hasNominated': false});
    }
  }

  Future<void> nominateSong(
      String songUri, String songName, String imageUrl) async {
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      DocumentSnapshot userSnapshot = await _firestoreService.firestore
          .collection('users')
          .doc(userId)
          .get();
      bool hasNominated =
          (userSnapshot.data() as Map<String, dynamic>)?['hasNominated'] ??
              false;
      if (hasNominated) {
        print('You have already nominated a song');
        return;
      }

      await _firestoreService.firestore
          .collection('users')
          .doc(userId)
          .update({'hasNominated': true});

      setState(() {
        _nominatedSong = songUri;
        _hasNominated = true;
        _searchResults = []; // Clear the search results
        _searchController.clear(); // Clear the text in the search bar
      });

      await _firestoreService.firestore
          .collection('nominated_songs')
          .doc(songUri)
          .set({
        'votes': 0,
        'name': songName,
        'voters': [],
        'imageUrl': imageUrl
      });

      startVoting(songName);

      // No need to check the player state and start the next song here.
      // It will be handled by the listener in initState when a new song is added to the nominated_songs collection and the player is paused.
    }
  }

  void startCountdownTimer(int duration) {
    const oneSec = const Duration(seconds: 1);
    int counter = duration ~/ 1000; // Convert duration to seconds

    _countdownTimerInstance?.cancel(); // Cancel the previous timer if it exists
    _countdownTimerInstance = Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (counter < 1) {
          timer.cancel();
          // The current song has ended, so start the next song
          await playNextSong();
        } else {
          counter--;
          int minutes = counter ~/ 60;
          int seconds = counter % 60;
          if (minutes > 0) {
            _countdownTimer.value = "${minutes}m ${seconds}s";
          } else {
            _countdownTimer.value = "${seconds}s";
          }
        }
      },
    );
  }

  Future<void> startVoting(String songName) async {
    if (_nominatedSong != null) {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        await _firestoreService.voteForSong(_nominatedSong!, songName, userId);
      }
      _nominatedSong = null;
    }
  }

  void voteForSong(String songUri, String songName) async {
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      await _firestoreService.voteForSong(songUri, songName, userId);
      DocumentSnapshot userSnapshot = await _firestoreService.firestore
          .collection('users')
          .doc(userId)
          .get();
      List<dynamic> votedSongs =
          (userSnapshot.data() as Map<String, dynamic>)?['votedSongs'] ?? [];
      setState(() {
        _votedSongs = List<String>.from(votedSongs);
      });
    }
  }

  Future<void> checkScopes(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('User data: $userData');
      } else {
        print(
            'Failed to get user data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  void initiateSpotifyAuthentication() async {
    if (_isAuthenticating) {
      print('Authentication process is already ongoing');
      return;
    }
    _isAuthenticating = true;
    try {
      final config = await _getConfig();
      final String clientId = config['CLIENT_ID'].toString();
      final String redirectUrl = config['REDIRECT_URL'].toString();

      final AuthorizationServiceConfiguration serviceConfiguration =
          AuthorizationServiceConfiguration(
              authorizationEndpoint:
                  "https://accounts.spotify.com/authorize", // authorization endpoint
              tokenEndpoint:
                  "https://accounts.spotify.com/api/token" // token endpoint
              );

      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          serviceConfiguration: serviceConfiguration,
          scopes: [
            'app-remote-control',
            'user-modify-playback-state',
            'user-read-currently-playing',
            'user-read-playback-state',
            'playlist-read-private',
            'playlist-modify-public',
          ],
        ),
      );

      if (result != null) {
        final String? accessToken = result.accessToken;
        final String? refreshToken = result.refreshToken;
        if (accessToken != null && refreshToken != null) {
          // Store the access token and refresh token for later use
          await getAccessToken(accessToken, refreshToken);
          await checkScopes(accessToken); // Check the scopes here
        } else {
          print('Access token or refresh token is null');
        }
      } else {
        print('Authorization process was cancelled or failed');
      }
    } catch (e) {
      print('Error initiating Spotify authentication: $e');
    } finally {
      _isAuthenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: _authService.userState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        User? user = snapshot.data;
        bool isMusicStreamer =
            user != null && user.email == 'user1@example.com';

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              Column(
                children: [
                  if (isMusicStreamer && _accessToken == null)
                    _buildConnectSpotifyButton(),
                  _buildSearchBar(),
                  _buildCountdownTimer(),
                  _buildMostVotedSong(),
                  _buildNominatedSongs(),
                ],
              ),
              if (_searchResults.isNotEmpty)
                Positioned(
                  top: kToolbarHeight + 35,
                  left: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: _buildSearchResults(),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Simple Spotify Player',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.skip_next, color: Colors.white),
          onPressed: () async {
            playNextSong();
          },
        ),
      ],
    );
  }

  Widget _buildConnectSpotifyButton() {
    return ElevatedButton(
      onPressed: () {
        initiateSpotifyAuthentication();
      },
      child: Text('Connect to Spotify'),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: !_hasNominated,
              decoration: InputDecoration(
                labelText: 'Search for a track',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                searchTrack(_searchController.text);
              } else {
                setState(() {
                  _searchResults = [];
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return ValueListenableBuilder<String>(
      valueListenable: _countdownTimer,
      builder: (context, value, child) {
        return Text("Time left to vote: $value seconds");
      },
    );
  }

  Widget _buildMostVotedSong() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firestoreService.getMostVotedSongDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.data == null) {
          return Text('No most voted song found');
        }

        final songDetails = snapshot.data!;
        final songName = songDetails['name'];
        final voteCount = songDetails['votes'];
        final imageUrl = songDetails['imageUrl'];

        return Column(
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: 150, height: 150),
            Text('Most voted song: $songName ($voteCount votes)'),
          ],
        );
      },
    );
  }

  Widget _buildNominatedSongs() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getNominatedSongs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        return Expanded(
          child: SingleChildScrollView(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final songDoc = snapshot.data!.docs[index];
                final songData = songDoc.data();
                final songUri = songDoc.id;
                final songName =
                    (songData as Map<String, dynamic>)?['name'] ?? 'Unknown';
                final voteCount =
                    (songData as Map<String, dynamic>)?['votes'] ?? 'Unknown';
                final imageUrl =
                    (songData as Map<String, dynamic>)?['imageUrl'];
                return ListTile(
                  tileColor: _votedSongs.contains(songUri)
                      ? Colors.green
                      : (index % 2 == 0 ? Colors.grey[200] : Colors.white),
                  title: Text('$songName ($voteCount votes)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: imageUrl != null ? Image.network(imageUrl) : null,
                  onTap: () {
                    voteForSong(songUri, songName);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final track = _searchResults[index];
          String? imageUrl;
          if (track['album']['images'].isNotEmpty) {
            imageUrl = track['album']['images'][0]['url'];
          }
          return ListTile(
            leading: imageUrl != null ? Image.network(imageUrl) : null,
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
            onTap: () async {
              await nominateSong(track['uri'], track['name'], imageUrl ?? '');
            },
          );
        },
      ),
    );
  }

  Future<bool> getPlayerState() async {
    if (_accessToken == null) {
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    final playerState = jsonDecode(response.body);
    return playerState['is_playing'] ?? false;
  }

  @override
  void dispose() {
    _songTimer?.cancel();
    _countdownTimerInstance?.cancel();
    super.dispose();
  }

  Future<void> searchTrack(String query) async {
    try {
      final config = await _getConfig();
      final String clientId = config['CLIENT_ID'].toString();
      final String clientSecret = config['CLIENT_SECRET'].toString();
      final String credentials = '$clientId:$clientSecret';
      final String basicCredentials = base64Encode(utf8.encode(credentials));

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $basicCredentials',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        final Map<String, dynamic> tokenResponse = jsonDecode(response.body);
        final String accessToken = tokenResponse['access_token'];

        final searchResponse = await http.get(
          Uri.parse('https://api.spotify.com/v1/search?type=track&q=$query'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (searchResponse.statusCode == 200) {
          final Map<String, dynamic> searchResults =
              jsonDecode(searchResponse.body);
          print(searchResults);
          setState(() {
            _searchResults = searchResults['tracks']['items'];
          });
        } else {
          print('Failed to load search results');
        }
      } else {
        print('Failed to obtain access token');
      }
    } catch (e) {
      print('Error searching track: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching track: $e'),
        ),
      );
      rethrow;
    }
  }

  Future<void> pauseCurrentSong(String accessToken) async {
    _isSongPlaying = false; // Update the song playing status
    final url = Uri.parse('https://api.spotify.com/v1/me/player/pause');

    final response = await http.put(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to pause song: ${response.statusCode}');
    }
  }

  Future<void> waitForSongToPause(String accessToken) async {
    Map<String, dynamic>? playerState;
    do {
      await Future.delayed(Duration(milliseconds: 500));
      try {
        final response = await http.get(
          Uri.parse('https://api.spotify.com/v1/me/player'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode != 200) {
          print(
              'Error getting player state: ${response.statusCode} ${response.reasonPhrase}');
          return;
        }

        playerState = jsonDecode(response.body);
      } catch (e) {
        print('Error making request to get player state: $e');
      }
    } while (playerState?['is_playing'] == true);
  }

  Future<void> startNextSong(String accessToken, String songUri) async {
    _isSongPlaying = true; // Add this line
    try {
      final response = await http.put(
        Uri.parse('https://api.spotify.com/v1/me/player/play'),
        headers: {'Authorization': 'Bearer $accessToken'},
        body: jsonEncode({
          'uris': [songUri]
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        print(
            'Error starting next song: ${response.statusCode} ${response.reasonPhrase}');
        return;
      }

      print('Response from start next song request: ${response.body}');

      // Wait for the song to start playing
      await waitForSongToStart(accessToken);

      // Update the song duration
      await updateSongDuration(accessToken);
    } catch (e) {
      print('Error making request to start next song: $e');
    }
  }

  Future<void> updateSongDuration(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        print(
            'Error getting player state: ${response.statusCode} ${response.reasonPhrase}');
        return;
      }

      print('Response from get player state request: ${response.body}');
      final playerState = jsonDecode(response.body);
      if (playerState != null && playerState['item'] != null) {
        int? duration = playerState['item']['duration_ms'];
        int? progress = playerState['progress_ms'];
        if (duration != null && progress != null) {
          // Calculate the remaining duration
          int remainingDuration = duration - progress;

          // Store the song duration in Firestore
          await _firestoreService.firestore
              .collection('current_song')
              .doc('duration')
              .set({'duration': remainingDuration}, SetOptions(merge: true));
          _songDuration.value =
              remainingDuration ~/ 1000; // Convert duration to seconds
        }
      }
    } catch (e) {
      print('Error making request to get player state: $e');
    }
  }

  Future<Map<String, dynamic>> _getConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading config: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading config: $e'),
        ),
      );
      rethrow;
    }
  }
}
