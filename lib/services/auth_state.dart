import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _expert;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get expert => _expert;

  set user(Map<String, dynamic>? value) {
    _user = value;
    notifyListeners();
  }

  set expert(Map<String, dynamic>? value) {
    _expert = value;
    notifyListeners();
  }

  bool get isUserLoggedIn => _user != null;
  bool get isExpertLoggedIn => _expert != null;
}
