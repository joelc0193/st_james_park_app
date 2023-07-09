import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../user_data.dart';

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

  Future<UserData?> getUserData(String userId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        QuerySnapshot serviceSnapshot =
            await doc.reference.collection('services').get();
        List<Service> services = serviceSnapshot.docs.map((serviceDoc) {
          final serviceData = serviceDoc.data();
          if (serviceData != null) {
            return Service.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          } else {
            throw Exception('Failed to load service data');
          }
        }).toList();
      }
    }
    return null;
  }

  Stream<DocumentSnapshot> getUserSnapshot(String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  Stream<DocumentSnapshot> getCurrentSongDuration() {
    return firestore.collection('current_song').doc('duration').snapshots();
  }

  Stream<List<Service>> getServicesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isInPark', isEqualTo: true)
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Service> services = [];
      for (var userDoc in querySnapshot.docs) {
        List<String> serviceIds = List<String>.from(userDoc['serviceIds']);
        for (var serviceId in serviceIds) {
          final serviceDoc = await FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .get();
          services.add(Service.fromMap(
            serviceDoc.id,
            serviceDoc.data() as Map<String, dynamic>,
          ));
        }
      }
      return services;
    });
  }

  Future<void> deleteCurrentSongDuration() async {
    await firestore.collection('current_song').doc('duration').delete();
  }

  Future<List<String>> voteForSong(
      String songUri, String songName, String userId) async {
    DocumentReference songRef =
        firestore.collection('nominated_songs').doc(songUri);
    DocumentReference userRef = firestore.collection('users').doc(userId);
    List<String> votedSongs = [];

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot songSnapshot = await transaction.get(songRef);
      DocumentSnapshot userSnapshot = await transaction.get(userRef);

      List<dynamic> voters = getVoters(songSnapshot);
      votedSongs =
          getVotedSongs(userSnapshot).map((song) => song as String).toList();

      if (userHasVotedForSong(votedSongs, songUri, voters, userId)) {
        removeVote(
            voters, userId, votedSongs, songUri, transaction, songRef, userRef);
      } else if (userHasNotVotedForSong(votedSongs, songUri, voters, userId)) {
        addVote(
            voters, userId, votedSongs, songUri, transaction, songRef, userRef);
      }
    });

    return votedSongs.map((song) => song).toList();
  }

  List<dynamic> getVoters(DocumentSnapshot songSnapshot) {
    return (songSnapshot.data() as Map<String, dynamic>)['voters'] ?? [];
  }

  List<dynamic> getVotedSongs(DocumentSnapshot userSnapshot) {
    return (userSnapshot.data() as Map<String, dynamic>)['votedSongs'] ?? [];
  }

  bool userHasVotedForSong(List<dynamic> votedSongs, String songUri,
      List<dynamic> voters, String userId) {
    return votedSongs.contains(songUri) && voters.contains(userId);
  }

  bool userHasNotVotedForSong(List<dynamic> votedSongs, String songUri,
      List<dynamic> voters, String userId) {
    return !votedSongs.contains(songUri) && !voters.contains(userId);
  }

  void removeVote(
      List<dynamic> voters,
      String userId,
      List<dynamic> votedSongs,
      String songUri,
      Transaction transaction,
      DocumentReference songRef,
      DocumentReference userRef) {
    voters.remove(userId);
    votedSongs.remove(songUri);
    transaction
        .update(songRef, {'votes': FieldValue.increment(-1), 'voters': voters});
    transaction.update(userRef, {'votedSongs': votedSongs});
  }

  void addVote(
      List<dynamic> voters,
      String userId,
      List<dynamic> votedSongs,
      String songUri,
      Transaction transaction,
      DocumentReference songRef,
      DocumentReference userRef) {
    voters.add(userId);
    votedSongs.add(songUri);
    transaction
        .update(songRef, {'votes': FieldValue.increment(1), 'voters': voters});
    transaction.update(userRef, {'votedSongs': votedSongs});
  }

  Stream<QuerySnapshot> getNominatedSongs() {
    return firestore
        .collection('nominated_songs')
        .orderBy('votes', descending: true)
        .snapshots();
  }

  Future<void> storeMostVotedSongDetails(
      Map<String, dynamic> songDetails) async {
    await firestore
        .collection('most_voted_song')
        .doc('current')
        .set(songDetails);
  }

  Stream<Map<String, dynamic>?> getMostVotedSongDetails() {
    return firestore
        .collection('most_voted_song')
        .doc('current')
        .snapshots()
        .map(
      (snapshot) {
        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>;
        } else {
          return null;
        }
      },
    );
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
    return data?['imageUrl'] as String?;
  }

  Stream<DocumentSnapshot> getUserLocationStream(String userId) {
    return firestore.collection('users').doc(userId).snapshots();
  }

  Future<void> updateSongDuration(String songUri, int duration) async {
    await firestore
        .collection('current_song')
        .doc('duration')
        .set({'duration': duration}, SetOptions(merge: true));
  }

  Future<void> clearNominations() async {
    await deleteAllNominatedSongsExceptSecondHighest();
    QuerySnapshot userSnapshot = await firestore.collection('users').get();
    for (var doc in userSnapshot.docs) {
      await doc.reference.update({'votedSongs': [], 'hasNominated': false});
    }
  }

  Future<String> getNextSongUri() async {
    String songUri = await getSongWithMostVotes();
    DocumentSnapshot songSnapshot =
        await firestore.collection('nominated_songs').doc(songUri).get();
    Map<String, dynamic> songDetails =
        songSnapshot.data() as Map<String, dynamic>;
    await storeMostVotedSongDetails(songDetails);
    return songUri;
  }

  Future<bool> userHasNominated(String userId) async {
    DocumentSnapshot userSnapshot =
        await firestore.collection('users').doc(userId).get();
    return (userSnapshot.data() as Map<String, dynamic>)['hasNominated'] ??
        false;
  }

  Future<void> setUserNominated(String userId, bool hasNominated) {
    return firestore
        .collection('users')
        .doc(userId)
        .update({'hasNominated': hasNominated});
  }

  Future<bool> songExists(String songUri) {
    return firestore
        .collection('nominated_songs')
        .doc(songUri)
        .get()
        .then((snapshot) => snapshot.exists);
  }

  Future<void> incrementSongVotes(String songUri) {
    return firestore
        .collection('nominated_songs')
        .doc(songUri)
        .update({'votes': FieldValue.increment(1)});
  }

  Future<void> createSong(String songUri, String songName, String imageUrl) {
    return firestore.collection('nominated_songs').doc(songUri).set(
        {'votes': 0, 'name': songName, 'voters': [], 'imageUrl': imageUrl});
  }

  Future<List<Service>> getServicesForUser(String userId) async {
    final QuerySnapshot querySnapshot = await firestore
        .collection('services')
        .where('userId', isEqualTo: userId) // Query services by user ID
        .get();
    return querySnapshot.docs.map((doc) {
      return Service.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<void> updateService(
      String userId, Service service, File? newImageFile) async {
    await firestore.collection('services').doc(service.id).set({
      ...service.toJson(),
      'userId':
          userId, // Ensure the user ID is included in the service document
    });

    if (newImageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('service_images')
          .child('${service.id}.jpg');
      await ref.putFile(newImageFile);
      final newImageUrl = await ref.getDownloadURL();
      await firestore
          .collection('services')
          .doc(service.id)
          .update({'imageUrl': newImageUrl});
    }
  }

  Future<void> updateUserProfile(
      String uid, String name, String message, String imageUrl) async {
    await firestore.collection('users').doc(uid).update({
      'name': name,
      'message': message,
      'imageUrl': imageUrl,
    });
  }

  Future<String> addService(String userId, Service service) async {
    DocumentReference docRef = await firestore.collection('services').add({
      ...service.toMap(),
      'userId': userId, // Add the user ID to the service document
    });

    // Add the service ID to the user's document
    DocumentReference userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({
      'serviceIds': FieldValue.arrayUnion([docRef.id]),
    });

    return docRef.id;
  }

  Future<void> deleteService(
      String userId, String serviceId, String imageUrl) async {
    await firestore.collection('services').doc(serviceId).delete();

    if (imageUrl.isNotEmpty) {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    }

    // Remove the service ID from the user's document
    DocumentReference userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({
      'serviceIds': FieldValue.arrayRemove([serviceId]),
    });
  }

  Future<String> uploadImage(File imageFile) async {
    final storage = FirebaseStorage.instance;
    final ref = storage
        .ref()
        .child('service_images')
        .child('${DateTime.now().toIso8601String()}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
