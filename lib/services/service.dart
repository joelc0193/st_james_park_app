class Service {
  final String id;
  final String type;
  final String description;
  final double price;
  final String imageUrl;
  final String userId; // Add this line

  Service({
    required this.id,
    required this.type,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.userId, // And this line
  });

  Service copyWith({
    String? id,
    String? type,
    String? description,
    double? price,
    String? imageUrl,
    String? userId, // Add this line
  }) {
    return Service(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId, // And this line
    );
  }

  factory Service.fromMap(String id, Map<String, dynamic> data) {
    return Service(
      id: id,
      type: data['type'],
      description: data['description'],
      price: data['price'],
      imageUrl: data['imageUrl'],
      userId: data['userId'], // And this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'userId': userId, // And this line
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
