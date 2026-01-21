// lib/services/api_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class ApiService {
  // Service endpoints (via API Gateway on port 4000)
  static String get restaurantService => EnvConfig.restaurants;
  static String get beverageService => EnvConfig.beverages;
  static String get eventService => EnvConfig.events;
  static String get expertService => EnvConfig.experts;
  static String get userService => EnvConfig.users;
  static String get socialService => EnvConfig.friends;
  static String get diaryService => EnvConfig.diary;
  static String get bookmarkService => EnvConfig.bookmarks;

  // Get Supabase client
  static final _supabase = Supabase.instance.client;

  // Headers helper with proper authentication
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    // Try to get token from Supabase session if not provided
    final sessionToken = token ?? _supabase.auth.currentSession?.accessToken;

    if (sessionToken != null) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }

    return headers;
  }

  // Get user ID header (for internal service communication)
  static Map<String, String> getUserHeaders(String userId,
      {String? role, String? token}) {
    final headers = getHeaders(token: token);
    headers['x-user-id'] = userId;

    if (role != null) {
      headers['x-user-role'] = role;
    }

    return headers;
  }

  // Get headers with current user's authentication
  static Future<Map<String, String>> getAuthHeaders() async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    final headers = {
      'Content-Type': 'application/json',
    };

    if (session?.accessToken != null) {
      headers['Authorization'] = 'Bearer ${session!.accessToken}';
    }

    if (user?.id != null) {
      headers['x-user-id'] = user!.id;
    }

    return headers;
  }

  // Helper method to get current user ID
  static String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Helper method to get current session token
  static String? getCurrentToken() {
    return _supabase.auth.currentSession?.accessToken;
  }

  // Helper to check if user is authenticated
  static bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }
}
