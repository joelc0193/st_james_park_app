import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:spotify_sdk/models/connection_status.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Timer? _debounce;
  // Add a ValueNotifier for the countdown timer
  ValueNotifier<String> _countdownTimer = ValueNotifier<String>("");
  ValueNotifier<int> _songDuration = ValueNotifier<int>(0);
  Timer?
      _countdownTimerInstance; // Add this line at the top of your _MusicPageState class
  bool _isSongPlaying = false;
  List<String> _votedSongs = [];

  Future<void> playNextSong() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    String? userEmail = auth.currentUser?.email;
    if (userEmail == "user1@example.com") {
      // replace with your email
      try {
        // Pause the current song
        await SpotifySdk.pause();

        // Wait for the player to confirm that the song is paused
        PlayerState? playerState;
        do {
          await Future.delayed(Duration(seconds: 1)); // Wait for 1 second
          playerState = await SpotifySdk.getPlayerState();
        } while (playerState?.isPaused == false);

        // Now that the previous song is paused, you can start the next song
        String songUri = await _firestoreService.getSongWithMostVotes();
        // Only attempt to play a song if a song URI was returned
        await SpotifySdk.play(spotifyUri: songUri);
        do {
          await Future.delayed(Duration(seconds: 1)); // Wait for 1 second
          playerState = await SpotifySdk.getPlayerState();
        } while (playerState?.track == null);
        if (playerState != null && playerState.track != null) {
          int? duration = playerState.track?.duration;
          if (duration != null) {
            // Store the song duration in Firestore
            await _firestoreService.firestore
                .collection('current_song')
                .doc('duration')
                .set({'duration': duration}, SetOptions(merge: true));

            // Cancel the previous timer if it exists
            _songTimer?.cancel();
            // Start a new timer for the current song
            _songTimer = Timer(Duration(milliseconds: duration - 1000), () {
              _isSongPlaying = false; // Set the flag to false
              playNextSong();
            });
            // Update the song duration and start the countdown timer
            _songDuration.value =
                duration ~/ 1000; // Convert duration to seconds
            _countdownTimerInstance
                ?.cancel(); // Cancel the previous countdown timer if it exists
            startCountdownTimer();

            _isSongPlaying = true; // Set the flag to true
          }
        }
        await _firestoreService
            .deleteAllNominatedSongsExceptSecondHighest(); // Clear the nominations
        // Clear the votedSongs list for each user
        QuerySnapshot userSnapshot1 =
            await _firestoreService.firestore.collection('users').get();
        for (var doc in userSnapshot1.docs) {
          await doc.reference.update({'votedSongs': []});
        }

        // Reset the hasNominated flag for all users
        QuerySnapshot userSnapshot2 =
            await _firestoreService.firestore.collection('users').get();
        for (var doc in userSnapshot2.docs) {
          await doc.reference.update({'hasNominated': false});
        }
      } catch (e) {
        print('error playing song: $e');
        if (e is Exception && e.toString() == 'Exception: No songs nominated') {
          // If no songs are nominated, pause the player
          await SpotifySdk.pause();
        }
      }
    }
  }

  void nominateSong(String songUri, String songName) async {
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
        _votedSongs
            .add(songUri); // Add the nominated song to the voted songs list
      });

      await _firestoreService.firestore
          .collection('nominated_songs')
          .doc(songUri)
          .set({'votes': 0, 'name': songName, 'voters': []});

      startVoting(songName);
    }
  }

  void startCountdownTimer() {
    const oneSec = const Duration(seconds: 1);
    int counter = _songDuration.value; // Set the initial counter value
    _countdownTimerInstance?.cancel(); // Cancel the previous timer if it exists
    _countdownTimerInstance = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (counter < 1) {
          timer.cancel();
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

  Future<void> connectToSpotifyRemote() async {
    try {
      final config = await _getConfig();
      var authenticationToken = await SpotifySdk.getAccessToken(
        clientId: config['CLIENT_ID'].toString(),
        redirectUrl: config['REDIRECT_URL'].toString(),
        scope:
            'app-remote-control,user-modify-playback-state,user-read-currently-playing,user-read-playback-state,playlist-read-private,playlist-modify-public',
      );
      print('Access token: $authenticationToken');
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: config['CLIENT_ID'].toString(),
        redirectUrl: config['REDIRECT_URL'].toString(),
        accessToken: authenticationToken,
      );
      print(result
          ? 'connect to spotify successful'
          : 'connect to spotify failed');
    } catch (e) {
      print('error connecting to spotify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  enabled:
                      !_hasNominated, // Disable the TextField if a song has been nominated
                  decoration: InputDecoration(
                    labelText: 'Search for a track',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (value.isNotEmpty) {
                        searchTrack(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                        });
                      }
                    });
                  },
                ),
              ),
              // Display the countdown timer
              ValueListenableBuilder<String>(
                valueListenable: _countdownTimer,
                builder: (context, value, child) {
                  return Text("Time left to vote: $value seconds");
                },
              ),
              StreamBuilder<QuerySnapshot>(
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
                              (songData as Map<String, dynamic>)?['name'] ??
                                  'Unknown';
                          final voteCount =
                              (songData as Map<String, dynamic>)?['votes'] ??
                                  'Unknown';

                          return ListTile(
                            tileColor: _votedSongs.contains(songUri)
                                ? Colors.green
                                : (index % 2 == 0
                                    ? Colors.grey[200]
                                    : Colors
                                        .white), // Alternate colors for each row
                            title: Text('$songName ($voteCount votes)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)), // Bold text
                            onTap: () {
                              voteForSong(songUri, songName);
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_searchResults.isNotEmpty)
            Positioned(
              top: kToolbarHeight + 35, // Adjust this value as needed
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: Container(
                color: Colors
                    .white, // Set the color to white or any color you prefer
                child: ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final track = _searchResults[index];
                    return ListTile(
                      title: Text(track['name']),
                      subtitle: Text(track['artists'][0]['name']),
                      onTap: () {
                        nominateSong(track['uri'], track['name']);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return Center(
      child: ElevatedButton(
        onPressed: connectToSpotifyRemote,
        child: const Text('Connect to Spotify'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Retrieve the hasNominated flag for the current user
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      _firestoreService.firestore
          .collection('users')
          .doc(userId)
          .get()
          .then((userSnapshot) {
        _hasNominated =
            (userSnapshot.data() as Map<String, dynamic>)?['hasNominated'] ??
                false;
      });
    }

    connectToSpotifyRemote().then((_) {
      // Listen for changes in the 'nominated_songs' collection
      _firestoreService.getNominatedSongs().listen((snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          // If there are any nominated songs, check the current player state
          try {
            var playerState = await SpotifySdk.getPlayerState();
            print('Player state: $playerState');
            if (playerState?.isPaused ?? false) {
              // If the player is not currently playing a song, start the next song
              playNextSong();
            }
          } catch (e) {
            print('Error getting player state: $e');
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _songTimer?.cancel();
    _countdownTimerInstance?.cancel();
    super.dispose();
  }

  Future<void> searchTrack(String query) async {
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
  }

  Future<Map<String, dynamic>> _getConfig() async {
    final jsonString = await rootBundle.loadString('assets/config.json');
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
