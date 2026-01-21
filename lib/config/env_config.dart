// lib/config/env_config.dart
class EnvConfig {
  static const String apiBaseUrl = 'https://api.sipzy.co.in/user';
  static const String authBaseUrl =
      'https://api.sipzy.co.in'; // Auth service (port 5000)

  static const String supabaseUrl = 'https://odtqequzbunyxpyjcoex.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdHFlcXV6YnVueXhweWpjb2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDQwNDUsImV4cCI6MjA4MjMyMDA0NX0.SPfRfV50CZ3AjV2cj09wok02kXsvlPqC-oj5eqYswtI';
  // API Endpoints (Gateway on port 4000)
  static String get restaurants => '$apiBaseUrl/api/restaurants';
  static String get beverages => '$apiBaseUrl/api/beverages';
  static String get events => '$apiBaseUrl/api/events';
  static String get users => '$apiBaseUrl/api/users';
  static String get bookmarks => '$apiBaseUrl/api/bookmarks';
  static String get diary => '$apiBaseUrl/api/diary';
  static String get friends => '$apiBaseUrl/api/friends';

  // Auth Endpoints (Auth service on port 5000)
  static String get authDevOtp => '$authBaseUrl/auth/dev-otp';

  // Feature Flags
  static const bool enableExpertMode = true;
  static const bool enableGames = true;
  static const bool enableEvents = true;
  static const bool enableSocial = true;

  // App Configuration
  static const int otpLength = 6;
  static const int minAge = 23;
  static const Duration requestTimeout = Duration(seconds: 15);

  // Validation
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
