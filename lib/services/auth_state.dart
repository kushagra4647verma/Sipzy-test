import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState extends ChangeNotifier {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _expert;
  String? _userToken;
  String? _expertToken;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get expert => _expert;
  String? get userToken => _userToken;
  String? get expertToken => _expertToken;

  set user(Map<String, dynamic>? value) {
    _user = value;
    notifyListeners();
    _saveToPrefs();
  }

  set expert(Map<String, dynamic>? value) {
    _expert = value;
    notifyListeners();
    _saveToPrefs();
  }

  set userToken(String? token) {
    _userToken = token;
    notifyListeners();
    _saveToPrefs();
  }

  set expertToken(String? token) {
    _expertToken = token;
    notifyListeners();
    _saveToPrefs();
  }

  bool get isUserLoggedIn => _user != null && _userToken != null;
  bool get isExpertLoggedIn => _expert != null && _expertToken != null;

  // Load persisted session on app start
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userJson = prefs.getString('user');
      final expertJson = prefs.getString('expert');
      final userTkn = prefs.getString('user_token');
      final expertTkn = prefs.getString('expert_token');

      if (userJson != null) {
        _user = Map<String, dynamic>.from(
          jsonDecode(userJson) as Map,
        );
      }

      if (expertJson != null) {
        _expert = Map<String, dynamic>.from(
          jsonDecode(expertJson) as Map,
        );
      }

      _userToken = userTkn;
      _expertToken = expertTkn;

      notifyListeners();
    } catch (e) {
      print('Failed to load session: $e');
    }
  }

  // Save session to persistent storage
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user));
      } else {
        await prefs.remove('user');
      }

      if (_expert != null) {
        await prefs.setString('expert', jsonEncode(_expert));
      } else {
        await prefs.remove('expert');
      }

      if (_userToken != null) {
        await prefs.setString('user_token', _userToken!);
      } else {
        await prefs.remove('user_token');
      }

      if (_expertToken != null) {
        await prefs.setString('expert_token', _expertToken!);
      } else {
        await prefs.remove('expert_token');
      }
    } catch (e) {
      print('Failed to save session: $e');
    }
  }

  void clear() {
    _user = null;
    _expert = null;
    _userToken = null;
    _expertToken = null;
    notifyListeners();
    _saveToPrefs();
  }

  void clearUser() {
    _user = null;
    _userToken = null;
    notifyListeners();
    _saveToPrefs();
  }

  void clearExpert() {
    _expert = null;
    _expertToken = null;
    notifyListeners();
    _saveToPrefs();
  }
}
