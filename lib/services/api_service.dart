// lib/services/api_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  // Base URLs
  static const String baseUrl = 'https://api.sipzy.co.in/user';

  // Service endpoints
  static const String restaurantService = '$baseUrl/restaurants';
  static const String beverageService = '$baseUrl/beverages';
  static const String eventService = '$baseUrl/events';
  static const String userService = '$baseUrl/users';
  static const String socialService = '$baseUrl/friends';
  static const String dairyService = '$baseUrl/diary';

  // Auth endpoints (assuming Supabase Auth)
  static const String authUrl =
      'https://odtqequzbunyxpyjcoex.supabase.co/auth/v1';

  // Get Supabase client
  static final _supabase = Supabase.instance.client;

  // Headers helper with proper authentication
  static Map<String, String> getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};

    // Try to get token from Supabase session if not provided
    final sessionToken = token ?? _supabase.auth.currentSession?.accessToken;

    if (sessionToken != null) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }

    return headers;
  }

  // Get user ID header (for internal service communication)
  static Map<String, String> getUserHeaders(String userId, {String? role}) {
    final headers = getHeaders();

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

    final headers = {'Content-Type': 'application/json'};

    if (session?.accessToken != null) {
      headers['Authorization'] = 'Bearer ${session!.accessToken}';
    }

    if (user?.id != null) {
      headers['x-user-id'] = user!.id;
    }

    return headers;
  }
}
