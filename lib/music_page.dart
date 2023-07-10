import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:st_james_park_app/music_page_view_model.dart';
import 'package:st_james_park_app/services/auth_service.dart';
import 'package:st_james_park_app/services/firestore_service.dart';
import 'package:st_james_park_app/services/spotify_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({Key? key}) : super(key: key);
  @override
  _MusicPageState createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  late final MusicPageViewModel _controller;
  @override
  void initState() {
    super.initState();
    _controller = MusicPageViewModel(
      notifyParent: _updateState,
      authService: Provider.of<AuthService>(context, listen: false),
      spotifyService: Provider.of<SpotifyService>(context, listen: false),
      firestoreService: Provider.of<FirestoreService>(context, listen: false),
    );
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthService>(context);

    // Listen to the errorNotifier and display an error message when necessary
    return ValueListenableBuilder<String?>(
        valueListenable: _controller.errorNotifier,
        builder: (context, error, child) {
          if (error != null) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            });
          }
          return StreamBuilder<User?>(
            stream: _controller.userState,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              return Scaffold(
                appBar: _buildAppBar(),
                body: Stack(
                  children: [
                    Column(
                      children: [
                        _buildSearchBar(),
                        _buildCountdownTimer(),
                        _buildMostVotedSong(),
                        _buildNominatedSongs(),
                      ],
                    ),
                    if (_controller.searchResults.isNotEmpty)
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
        });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Simple Spotify Player',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: () async {
            try {
              await _controller.playNextSong();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error playing next song: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                _controller.updateSearchText(value);
              },
              enabled: !_controller.hasNominatedNotifier.value,
              decoration: InputDecoration(
                labelText: 'Search for a track',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              if (_controller.searchText.isNotEmpty) {
                try {
                  await _controller.searchTrack(_controller.searchText);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error searching track: $e'),
                    ),
                  );
                }
              } else {
                setState(() {
                  _controller.searchResults = [];
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
      valueListenable: _controller.countdownTimer,
      builder: (context, value, child) {
        return Text("Time left to vote: $value seconds");
      },
    );
  }

  Widget _buildMostVotedSong() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _controller.getMostVotedSongDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.data == null) {
          return const Text('No most voted song found');
        }
        final songDetails = snapshot.data!;
        final songName = songDetails['name'];
        final voteCount = songDetails['votes'];
        final imageUrl = songDetails['imageUrl'];
        return Column(
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: 150, height: 150),
            Text('Most voted song: $songName($voteCount votes)'),
          ],
        );
      },
    );
  }

  Widget _buildNominatedSongs() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getNominatedSongs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
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
                    (songData as Map<String, dynamic>)['name'] ?? 'Unknown';
                final voteCount = (songData)['votes'] ?? 'Unknown';
                final imageUrl = (songData)['imageUrl'];
                return ListTile(
                  tileColor:
                      _controller.votedSongsNotifier.value.contains(songUri)
                          ? Colors.green
                          : (index % 2 == 0 ? Colors.grey[200] : Colors.white),
                  title: Text('$songName($voteCount votes)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  leading: imageUrl != null ? Image.network(imageUrl) : null,
                  onTap: () {
                    _controller.voteForSong(songUri, songName);
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
        separatorBuilder: (context, index) => const Divider(
          color: Colors.grey,
        ),
        itemCount: _controller.searchResults.length,
        itemBuilder: (context, index) {
          final track = _controller.searchResults[index];
          String? imageUrl;
          if (track['album']['images'].isNotEmpty) {
            imageUrl = track['album']['images'][0]['url'];
          }
          return ListTile(
            leading: imageUrl != null ? Image.network(imageUrl) : null,
            title: Text(track['name']),
            subtitle: Text(track['artists'][0]['name']),
            onTap: () async {
              await _controller.nominateSongAndClearSearch(
                  track['uri'], track['name'], imageUrl ?? '');
              _controller.searchResults = [];
              _controller.searchController.clear();
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
