// lib/config/env_config.dart
class EnvConfig {
  static const String apiBaseUrl = 'https://api.sipzy.co.in/user';

  static const String supabaseUrl = 'https://odtqequzbunyxpyjcoex.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdHFlcXV6YnVueXhweWpjb2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDQwNDUsImV4cCI6MjA4MjMyMDA0NX0.SPfRfV50CZ3AjV2cj09wok02kXsvlPqC-oj5eqYswtI';

  // API Endpoints
  static String get restaurants => '$apiBaseUrl/restaurants';
  static String get beverages => '$apiBaseUrl/beverages';
  static String get events => '$apiBaseUrl/events';
  static String get users => '$apiBaseUrl/users';
  static String get bookmarks => '$apiBaseUrl/bookmarks';
  static String get diary => '$apiBaseUrl/diary';
  static String get friends => '$apiBaseUrl/friends';

  // Feature Flags
  static const bool enableExpertMode = true;
  static const bool enableGames = true;
  static const bool enableEvents = true;
  static const bool enableSocial = true;

  // App Configuration
  static const int otpLength = 6;
  static const int minAge = 23;
  static const Duration requestTimeout =
      Duration(seconds: 15); // Increased from 30

  // Validation
  static bool get isConfigured {
    return supabaseUrl != 'https://odtqequzbunyxpyjcoex.supabase.co' &&
        supabaseAnonKey !=
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdHFlcXV6YnVueXhweWpjb2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDQwNDUsImV4cCI6MjA4MjMyMDA0NX0.SPfRfV50CZ3AjV2cj09wok02kXsvlPqC-oj5eqYswtI';
  }
}
