```dart
class Message {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;

  Message({this.id, this.userId, this.content, this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
```