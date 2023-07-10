import 'package:st_james_park_app/service.dart';

class UserData {
  final String name;
  final String imageUrl;
  final String message;
  final List<Service>? services;

  UserData({
    required this.name,
    required this.imageUrl,
    required this.message,
    this.services,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    var serviceList = map['services'] as List?;
    List<Service>? services = serviceList
        ?.map((item) => Service(
              id: item['id'],
              type: item['type'],
              description: item['description'],
              price: item['price'],
              imageUrl: item['imageUrl'],
              userId: item['userId'], // Add this line
            ))
        .toList();

    return UserData(
      name: map['name'],
      imageUrl: map['imageUrl'],
      message: map['message'],
      services: services,
    );
  }
}
