import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/spotify_service.dart';

class MusicPageViewModel {
  ValueNotifier<bool> hasNominatedNotifier = ValueNotifier<bool>(false);
  ValueNotifier<List<String>> votedSongsNotifier =
      ValueNotifier<List<String>>([]);
  Timer _countdownTimerInstance;
  late final SpotifyService _spotifyService;
  late final AuthService _authService;
  final ValueNotifier<List<dynamic>> _searchResultsNotifier =
      ValueNotifier<List<dynamic>>([]);
  final TextEditingController _searchController = TextEditingController();
  late final FirestoreService _firestoreService;
  final ValueNotifier<int> _songDuration = ValueNotifier<int>(0);
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  bool _isFirestoreListenerSetUp = false;
  final VoidCallback notifyParent;
  ValueNotifier<String> _countdownTimer = ValueNotifier<String>("");

  // Expose an error state that the UI can listen to
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);

  bool get songIsPlaying => _countdownTimerInstance.isActive;

  ValueNotifier<String> get countdownTimer => _countdownTimer;

  set countdownTimer(ValueNotifier<String> timer) {
    _countdownTimer = timer;
  }

  Timer get countdownTimerInstance => _countdownTimerInstance;

  MusicPageViewModel({
    required this.notifyParent,
    required AuthService authService,
    required SpotifyService spotifyService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _spotifyService = spotifyService,
        _firestoreService = firestoreService,
        _countdownTimerInstance = Timer(Duration.zero, () {}) {
    _setupListeners();
  }
  List<dynamic> get searchResults => _searchResultsNotifier.value;
  set searchResults(value) => _searchResultsNotifier.value = value;
  void _setupListeners() {
    _setupAuthListener();
    _setupSongDurationListener();
    _setupNominatedSongsListener();
    hasNominatedNotifier.addListener(_updateState);
    votedSongsNotifier.addListener(_updateState);
    _spotifyService.accessTokenNotifier.addListener(_updateState);
    _searchResultsNotifier.addListener(_updateState);
  }

  TextEditingController get searchController => _searchController;
  void _updateState() {
    notifyParent();
  }

  Stream<User?> get userState => _authService.userState;
  String? get accessToken => _spotifyService.accessToken;
  void _setupAuthListener() {
    _authService.userState.listen((User? user) {
      if (user != null && user.email == 'user1@example.com') {
        Future.microtask(() async {
          try {
            await _spotifyService.initiateSpotifyAuthentication();
          } catch (e) {
            errorNotifier.value = 'Error during Spotify authentication: $e';
          }
        });
      }
      String? userId = _authService.getCurrentUserId();
      if (userId != null && !_isFirestoreListenerSetUp) {
        _isFirestoreListenerSetUp = true;
        _setupUserSnapshotListener(userId);
      }
    });
  }

  void _setupUserSnapshotListener(String userId) {
    _firestoreService.getUserSnapshot(userId).listen((userSnapshot) {
      hasNominatedNotifier.value =
          (userSnapshot.data() as Map<String, dynamic>)['hasNominated'] ??
              false;
      votedSongsNotifier.value = List<String>.from(
          (userSnapshot.data() as Map<String, dynamic>)['votedSongs'] ?? []);
    });
  }

  void _setupSongDurationListener() {
    _firestoreService.getCurrentSongDuration().listen((snapshot) {
      if (snapshot.exists) {
        int duration =
            (snapshot.data() as Map<String, dynamic>)['duration'] ?? 0;
        startCountdownTimer(duration);
      }
    });
  }

  Future<void> playNextSong() async {
    try {
      String songUri = await _firestoreService.getNextSongUri();
      await _spotifyService.startNextSong(songUri);
      await updateSongDuration(songUri);
      await _firestoreService.clearNominations();
      await _firestoreService.firestore;
      await _firestoreService.deleteCurrentSongDuration();
    } catch (e) {
      if (e is Exception && e.toString() == 'Exception:No songs nominated') {
        errorNotifier.value =
            'No songs have been nominated yet. Please nominate a song.';
      } else if (e is Exception && e.toString().contains('403')) {
        try {
          await _spotifyService.refreshAccessToken();
          playNextSong();
        } catch (refreshError) {
          errorNotifier.value =
              'Error refreshing access token. Please try again.';
          errorNotifier.value = 'Error refreshing access token: $refreshError';
        }
      } else {
        errorNotifier.value = 'An unexpected error occurred. Please try again.';
        errorNotifier.value = 'Unexpected error: $e';
      }
    }
  }

  void _setupNominatedSongsListener() {
    _firestoreService.getNominatedSongs().listen((snapshot) async {
      final addedDocs = snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added);
      if (addedDocs.length == 1 && !songIsPlaying) {
        User? user = _authService.getCurrentUser();
        if (user != null && user.email == 'user1@example.com') {
          await playNextSong();
        }
      }
    });
  }

  Stream<Map<String, dynamic>?> getMostVotedSongDetails() {
    return _firestoreService.getMostVotedSongDetails();
  }

  Stream<QuerySnapshot> getNominatedSongs() {
    return _firestoreService.getNominatedSongs();
  }

  ValueNotifier<String?> get accessTokenNotifier =>
      _spotifyService.accessTokenNotifier;

  // UI logic
  Future<void> nominateSongAndClearSearch(
      String songUri, String songName, String imageUrl) async {
    try {
      await nominateSong(songUri, songName, imageUrl);
      _searchResultsNotifier.value = [];
      _searchController.clear();
    } catch (e) {
      errorNotifier.value = 'Error nominating song: $e';
    }
  }

  Future<void> updateSongDuration(String songUri) async {
    _songDuration.value = await _spotifyService.fetchSongDuration(
        songUri, accessTokenNotifier.value!);
    await _firestoreService.updateSongDuration(songUri, _songDuration.value);
  }

  Future<void> nominateSong(
      String songUri, String songName, String imageUrl) async {
    try {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        bool hasNominated = await _firestoreService.userHasNominated(userId);
        if (hasNominated) {
          errorNotifier.value = 'You have already nominated a song';
          return;
        }
        await _firestoreService.setUserNominated(userId, true);
        hasNominatedNotifier.value = true;

        bool songExists = await _firestoreService.songExists(songUri);
        if (songExists) {
          await _firestoreService.incrementSongVotes(songUri);
        } else {
          await _firestoreService.createSong(songUri, songName, imageUrl);
        }
        await _firestoreService.voteForSong(songUri, songName, userId);
      }
    } catch (e) {
      errorNotifier.value = 'Error nominating song: $e';
    }
  }

  Future<void> voteForSong(String songUri, String songName) async {
    try {
      String? userId = _authService.getCurrentUserId();
      if (userId != null) {
        List<String> votedSongs =
            await _firestoreService.voteForSong(songUri, songName, userId);
        votedSongsNotifier.value = votedSongs;
      }
    } catch (e) {
      errorNotifier.value = 'Error voting for song: $e';
    }
  }

  Future<bool> getPlayerState() async {
    try {
      if (_spotifyService.accessTokenNotifier.value == null) {
        throw Exception('Access token not found');
      }
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player'),
        headers: {
          'Authorization': 'Bearer ${_spotifyService.accessTokenNotifier.value}'
        },
      );
      final playerState = jsonDecode(response.body);
      return playerState['is_playing'] ?? false;
    } catch (e) {
      errorNotifier.value = 'Error getting player state: $e';
      return false;
    }
  }

  Future<List<dynamic>> searchTrack(String query) async {
    return searchResults = await _spotifyService.searchTrack(query);
  }

  void clearSearchResults() {
    _searchResultsNotifier.value = [];
  }

  void startCountdownTimer(int duration) {
    const oneSec = Duration(seconds: 1);
    int counter = duration ~/ 1000;

    _countdownTimerInstance.cancel();

    _countdownTimerInstance = Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (counter < 1) {
          timer.cancel();
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

  void dispose() {
    hasNominatedNotifier.removeListener(_updateState);
    votedSongsNotifier.removeListener(_updateState);
    _spotifyService.accessTokenNotifier.removeListener(_updateState);
    _searchResultsNotifier.removeListener(_updateState);
    countdownTimerInstance.cancel();
    _searchResultsNotifier.removeListener(_updateState);
  }
}
