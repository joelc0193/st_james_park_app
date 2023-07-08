import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:st_james_park_app/services/firestore_service.dart';

class SpotifyService extends ChangeNotifier {
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final ValueNotifier<String?> _accessTokenNotifier =
      ValueNotifier<String?>(null);
  String? _refreshToken;

  SpotifyService();

  Future<void> getAccessToken(String accessToken,
      [String? refreshToken]) async {
    accessTokenNotifier.value = accessToken;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
  }

  ValueNotifier<String?> get accessTokenNotifier => _accessTokenNotifier;

  String? get accessToken => _accessTokenNotifier.value;
  set accessToken(String? value) => _accessTokenNotifier.value = value;

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    accessTokenNotifier.value = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> refreshAccessToken() async {
    // Assuming you have a method to get the client ID and secret from your config
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
      accessTokenNotifier.value = newAccessToken;
    } else {
      throw Exception('Failed to refresh access token: ${response.statusCode}');
    }
  }

  Future<void> initiateSpotifyAuthentication() async {
    try {
      // Assuming you have a method to get the client ID and redirect URL from your config
      final config = await _getConfig();
      final String clientId = config['CLIENT_ID'].toString();
      final String redirectUrl = config['REDIRECT_URL'].toString();

      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl:
              'https://accounts.spotify.com/.well-known/openid-configuration',
          scopes: [
            'user-read-private',
            'playlist-read-private',
            'user-read-email',
            'user-modify-playback-state'
          ],
        ),
      );

      if (result != null) {
        accessTokenNotifier.value = result.accessToken;
        _refreshToken = result.refreshToken;
      } else {
        throw Exception('Failed to authenticate');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pauseCurrentSong() async {
    if (accessTokenNotifier.value == null) {
      throw Exception('Access token not found');
    }

    final url = Uri.parse('https://api.spotify.com/v1/me/player/pause');

    final response = await http.put(
      url,
      headers: {'Authorization': 'Bearer ${accessTokenNotifier.value}'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to pause song: ${response.statusCode}');
    }
  }

  Future<void> startNextSong(String songUri) async {
    if (accessTokenNotifier.value == null) {
      throw Exception('Access token not found');
    }

    final response = await http.put(
      Uri.parse('https://api.spotify.com/v1/me/player/play'),
      headers: {'Authorization': 'Bearer ${accessTokenNotifier.value}'},
      body: jsonEncode({
        'uris': [songUri]
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error starting next song: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> searchTrack(String query) async {
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
          return searchResults['tracks']['items'];
        } else {
          throw Exception('Failed to load search results');
        }
      } else {
        throw Exception('Failed to obtain access token');
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  Future<Map<String, dynamic>> _getConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading config: $e');
    }
  }

  Future<int> fetchSongDuration(String songUri, String accessToken) async {
    String songId = songUri.split(':').last;
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/tracks/$songId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      var errorDetail = 'Unknown error';
      try {
        var errorResponse = jsonDecode(response.body);
        errorDetail = errorResponse['error']['message'];
      } catch (e) {
        throw Exception('Error parsing error message: $e');
      }
      throw Exception(
          'Error getting track info: ${response.statusCode}, $errorDetail');
    }

    final trackInfo = jsonDecode(response.body);
    int? duration = trackInfo['duration_ms'];
    return duration ?? 0;
  }
}
