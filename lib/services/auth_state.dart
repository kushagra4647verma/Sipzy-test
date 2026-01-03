class AuthState {
  Map<String, dynamic>? user;
  Map<String, dynamic>? expert;

  bool get isUserLoggedIn => user != null;
  bool get isExpertLoggedIn => expert != null;
}
