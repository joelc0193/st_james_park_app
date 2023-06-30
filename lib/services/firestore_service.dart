import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:st_james_park_app/user_data.dart';

class FirestoreService {
  final FirebaseFirestore firestore;

  FirestoreService({required this.firestore});

  FieldValue getServerTimestamp() {
    return FieldValue.serverTimestamp();
  }

  Stream<DocumentSnapshot> getAdminNumbers() {
    return firestore.collection('numbers').doc('numbers').snapshots();
  }

  Future<void> updateAdminNumbers(Map<String, int> numbers) async {
    await firestore.collection('numbers').doc('numbers').set({
      ...numbers,
      'Updated': getServerTimestamp(),
    });
  }

  Future<void> voteForSong(
      String songUri, String songName, String userId) async {
    DocumentReference songRef =
        firestore.collection('nominated_songs').doc(songUri);
    DocumentReference userRef = firestore.collection('users').doc(userId);

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot songSnapshot = await transaction.get(songRef);
      DocumentSnapshot userSnapshot = await transaction.get(userRef);

      List<dynamic> voters =
          (songSnapshot.data() as Map<String, dynamic>)?['voters'] ?? [];
      List<dynamic> votedSongs =
          (userSnapshot.data() as Map<String, dynamic>)?['votedSongs'] ?? [];

      if (votedSongs.contains(songUri) && voters.contains(userId)) {
        // The user has already voted for this song, so remove their vote
        voters.remove(userId);
        votedSongs.remove(songUri);
        transaction.update(
            songRef, {'votes': FieldValue.increment(-1), 'voters': voters});
        transaction.update(userRef, {'votedSongs': votedSongs});
      } else if (!votedSongs.contains(songUri) && !voters.contains(userId)) {
        // The user has not voted for this song yet, so they can vote
        voters.add(userId);
        votedSongs.add(songUri);
        transaction.update(
            songRef, {'votes': FieldValue.increment(1), 'voters': voters});
        transaction.update(userRef, {'votedSongs': votedSongs});
      }
    });
  }

  Stream<QuerySnapshot> getNominatedSongs() {
    return firestore.collection('nominated_songs').snapshots();
  }

  Future<String> getSongWithMostVotes() async {
    QuerySnapshot snapshot = await firestore
        .collection('nominated_songs')
        .orderBy('votes', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No songs nominated');
    }

    // The song with the most votes is the first document in the snapshot
    DocumentSnapshot songWithMostVotes = snapshot.docs.first;
    return songWithMostVotes
        .id; // The ID of the document is the URI of the song
  }

  Future<void> deleteAllNominatedSongsExceptSecondHighest() async {
    QuerySnapshot snapshot = await firestore
        .collection('nominated_songs')
        .orderBy('votes', descending: true)
        .get();
    if (snapshot.docs.length > 1) {
      for (var i = 0; i < snapshot.docs.length; i++) {
        if (i != 1) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } else if (snapshot.docs.length == 1) {
      await snapshot.docs[0].reference.delete();
    }
  }

  Stream<QuerySnapshot> getUsersInPark() {
    return firestore
        .collection('users')
        .where('isInPark', isEqualTo: true)
        .snapshots();
  }

  Future<void> updateUserLocation(
      String userId, GeoPoint location, bool isInPark) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'location': location,
        'isInPark': isInPark,
      });
    } catch (e) {
      print('Error updating user location: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(
      String userId, String name, String message, String imageUrl) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'name': name,
        'user_message': message,
        'image_url': imageUrl,
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<String> uploadMedia(Uint8List? mediaData) async {
    if (mediaData != null) {
      String fileName =
          'uploads/${DateTime.now().toIso8601String()}'; // Generate a unique file name
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putData(mediaData);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Update Firestore with the new media URL
      await firestore.collection('spotlight').doc('spotlight').update({
        'media_url': downloadUrl,
      });

      return downloadUrl;
    } else {
      // Update Firestore with an empty string if no media is selected
      await firestore.collection('spotlight').doc('spotlight').update({
        'media_url': '',
      });

      return '';
    }
  }

  Future<void> uploadText(String text) async {
    try {
      await firestore.collection('spotlight').doc('spotlight').update({
        'message': text,
      });
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<String?> getUploadedText() async {
    DocumentSnapshot doc =
        await firestore.collection('spotlight').doc('spotlight').get();
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    return data?['message'] as String?;
  }

  Future<String?> getSpotlightImageUrl() async {
    DocumentSnapshot doc =
        await firestore.collection('spotlight').doc('spotlight').get();
    Map<String, dynamic>? data = doc.data()! as Map<String, dynamic>?;
    return data?['image_url'] as String?;
  }

  Stream<DocumentSnapshot> getUserLocationStream(String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  Future<UserData> getUserData(String userId) async {
    DocumentSnapshot doc =
        await firestore.collection('users').doc(userId).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserData(
      name: data['name'],
      message: data['user_message'],
      imageUrl: data['image_url'],
    );
  }
}
