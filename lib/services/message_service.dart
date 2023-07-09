import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/message.dart';
import '../utils/timer_util.dart';

class MessageService {
  final List<Message> _messages = [];

  Stream<List<Message>> get messagesStream => Stream.value(_messages);

  void createMessage(User user, String content) {
    final message = Message(user, content, DateTime.now());
    _messages.add(message);

    TimerUtil.runAfter(Duration(seconds: 10), () {
      _messages.remove(message);
    });
  }
}