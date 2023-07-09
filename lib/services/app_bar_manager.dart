import 'package:flutter/material.dart';

class AppBarManager extends ChangeNotifier {
  bool _showBackButton = false;

  bool get showBackButton => _showBackButton;

  void show() {
    _showBackButton = true;
    notifyListeners();
  }

  void hide() {
    _showBackButton = false;
    notifyListeners();
  }
}
