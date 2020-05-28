import 'package:flutter/foundation.dart';

class AppModel extends ChangeNotifier {
  bool _showInstructions = true;

  bool get showInstructions => _showInstructions;

  set showInstructions(bool value) {
    _showInstructions = value;
    notifyListeners();
  }
}
