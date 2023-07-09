import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/message.dart';
import '../widgets/map_widget.dart';
import '../services/message_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<User> users = [];
  List<Message> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Park Map'),
      ),
      body: Stack(
        children: users.map((user) {
          return MapWidget(
            user: user,
            message: messages.firstWhere((message) => message.userId == user.id, orElse: () => null),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final message = await showDialog<Message>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Write a message'),
              content: TextField(
                onSubmitted: (text) {
                  Navigator.of(context).pop(Message(text, Provider.of<User>(context, listen: false).id));
                },
              ),
            ),
          );

          if (message != null) {
            setState(() {
              messages.add(message);
            });

            Provider.of<MessageService>(context, listen: false).displayMessage(message);
          }
        },
        child: Icon(Icons.message),
      ),
    );
  }
}