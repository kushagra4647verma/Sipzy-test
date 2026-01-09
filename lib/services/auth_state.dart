import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _expert;
  String? _sessionToken;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get expert => _expert;
  String? get sessionToken => _sessionToken;

  set user(Map<String, dynamic>? value) {
    _user = value;
    notifyListeners();
  }

  set expert(Map<String, dynamic>? value) {
    _expert = value;
    notifyListeners();
  }

  set sessionToken(String? token) {
    _sessionToken = token;
    notifyListeners();
  }

  bool get isUserLoggedIn => _user != null;
  bool get isExpertLoggedIn => _expert != null;

  void clear() {
    _user = null;
    _expert = null;
    _sessionToken = null;
    notifyListeners();
  }
}
