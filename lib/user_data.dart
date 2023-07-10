import 'package:st_james_park_app/listing.dart';

class UserData {
  final String name;
  final String imageUrl;
  final String message;
  final List<String> interests; // add this
  final List<String> goals; // add this
  final List<Listing>? services;

  UserData({
    required this.name,
    required this.imageUrl,
    required this.message,
    required this.interests, // add this
    required this.goals, // add this
    this.services,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    var serviceList = map['services'] as List?;
    List<Listing>? services = serviceList
        ?.map((item) => Listing(
              id: item['id'],
              type: item['type'],
              description: item['description'],
              price: item['price'],
              imageUrl: item['imageUrl'],
              userId: item['userId'],
            ))
        .toList();

    List<String> interests =
        List<String>.from(map['interests'] ?? []); // add this
    List<String> goals = List<String>.from(map['goals'] ?? []); // add this

    return UserData(
      name: map['name'],
      imageUrl: map['imageUrl'],
      message: map['message'],
      interests: interests, // add this
      goals: goals, // add this
      services: services,
    );
  }
}
