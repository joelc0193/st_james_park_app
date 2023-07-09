class Service {
  final String id;
  final String type;
  final String description;
  final double price;
  final String imageUrl; // Add this line

  Service({
    required this.id,
    required this.type,
    required this.description,
    required this.price,
    required this.imageUrl, // And this line
  });
  Service copyWith({
    String? id,
    String? type,
    String? description,
    double? price,
    String? imageUrl,
  }) {
    return Service(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Modify your toJson and fromMap methods to include the imageUrl
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'description': description,
        'price': price,
        'imageUrl': imageUrl, // And this line
      };

  factory Service.fromMap(String id, Map<String, dynamic> map) {
    return Service(
      id: id,
      type: map['type'],
      description: map['description'],
      price: map['price'],
      imageUrl: map['imageUrl'],
    );
  }

  // If you have a toMap method, it should look like this
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}

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
