// lib/services/api_service.dart
class ApiService {
  // Base URLs
  static const String baseUrl = 'https://api.sipzy.co.in/user';

  // Service endpoints
  static const String restaurantService = '$baseUrl/restaurants';
  static const String beverageService = '$baseUrl/beverages';
  static const String eventService = '$baseUrl/events';
  static const String userService = '$baseUrl/users';
  static const String socialService = '$baseUrl/friends';

  // Auth endpoints (assuming Supabase Auth)
  static const String authUrl =
      'https://odtqequzbunyxpyjcoex.supabase.co/auth/v1';

  // Headers helper
  static Map<String, String> getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
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
}
