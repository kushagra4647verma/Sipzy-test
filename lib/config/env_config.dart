class EnvConfig {
  // Backend Base URLs - DigitalOcean Setup
  static const String baseUrl = 'https://api.sipzy.co.in/user';

  // Auth Service (Port 5000)
  static const String authServiceUrl = '$baseUrl:5000';

  // User Services (Port 4000 - API Gateway)
  static const String apiBaseUrl = '$baseUrl:4000';

  // Supabase Configuration
  static const String supabaseUrl = 'https://odtqequzbunyxpyjcoex.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdHFlcXV6YnVueXhweWpjb2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDQwNDUsImV4cCI6MjA4MjMyMDA0NX0.SPfRfV50CZ3AjV2cj09wok02kXsvlPqC-oj5eqYswtI';

  // API Endpoints (User Services via Gateway)
  static String get restaurants => '$apiBaseUrl/api/restaurants';
  static String get beverages => '$apiBaseUrl/api/beverages';
  static String get events => '$apiBaseUrl/api/events';
  static String get experts => '$apiBaseUrl/api/experts';
  static String get users => '$apiBaseUrl/api/users';
  static String get bookmarks => '$apiBaseUrl/api/bookmarks';
  static String get diary => '$apiBaseUrl/api/diary';
  static String get friends => '$apiBaseUrl/api/friends';

  // Auth Endpoints (Auth Service)
  static String get authSendOtp => '$authServiceUrl/auth/sms-hook';
  static String get authDevOtp => '$authServiceUrl/auth/dev-otp';
  static String get authVerify => '$authServiceUrl/auth/verify';

  // Feature Flags
  static const bool enableExpertMode = true;
  static const bool enableGames = false;
  static const bool enableEvents = true;
  static const bool enableSocial = true;

  // App Configuration
  static const int otpLength = 6;
  static const int minAge = 25;
  static const Duration requestTimeout = Duration(seconds: 30);

  // Debug Mode
  static const bool isDevelopment = true;

  // Validation
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
