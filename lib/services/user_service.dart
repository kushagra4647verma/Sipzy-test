// lib/services/user_service.dart
// ENHANCED VERSION - BATCH 1: User Profile & Stats APIs
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  static const String baseUrl = 'https://api.sipzy.co.in/users';

  Future<Map<String, String>> _getHeaders() async {
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

  // ============ USER PROFILE ============

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_my_profile'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get profile error: $e');
      return null;
    }
  }

  /// PATCH /users/me
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/patch_my_profile'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update profile error: $e');
      return false;
    }
  }

  /// GET /users/{user_id}/stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_stats/$userId/stats'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return {
        'ratingsCount': 0,
        'friendsCount': 0,
        'badgesCount': 0,
        'bookmarksCount': 0,
        'diaryEntriesCount': 0,
      };
    } catch (e) {
      print('❌ Get stats error: $e');
      return {
        'ratingsCount': 0,
        'friendsCount': 0,
        'badgesCount': 0,
        'bookmarksCount': 0,
        'diaryEntriesCount': 0,
      };
    }
  }

  /// GET /users/{user_id}/ratings
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_ratings/$userId/ratings'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
            data['data']['beverageRatings'] ?? [],
          );
        }
      }

      return [];
    } catch (e) {
      print('❌ Get ratings error: $e');
      return [];
    }
  }

  // ============ DIARY ============

  /// GET /users/diary
  Future<List> getDiary() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/diary/get_diary'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get diary error: $e');
      return [];
    }
  }

  /// POST /users/diary/
  Future<bool> addDiaryEntry(Map<String, dynamic> entry) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/diary/post_diary'),
            headers: headers,
            body: jsonEncode(entry),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Add diary error: $e');
      return false;
    }
  }

  /// PATCH /users/diary/{diary_entry_id}
  Future<bool> updateDiaryEntry(
      String entryId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/diary/patch_diary/$entryId'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update diary error: $e');
      return false;
    }
  }

  /// DELETE /users/diary/{diary_entry_id}
  Future<bool> deleteDiaryEntry(String entryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/diary/delete_diary/$entryId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Delete diary error: $e');
      return false;
    }
  }

  // ============ BOOKMARKS ============

  /// GET /users/bookmarks
  Future<List> getBookmarks() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/bookmarks/get_bookmarks'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get bookmarks error: $e');
      return [];
    }
  }

  /// POST /users/bookmarks/{restaurant_id}
  Future<bool> toggleBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookmarks/post_bookmark/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      return false;
    }
  }

  /// DELETE /users/bookmarks/{restaurant_id}
  Future<bool> removeBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/bookmarks/delete_bookmark/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Remove bookmark error: $e');
      return false;
    }
  }

  // ============ FRIENDS ============

  /// GET /users/friends
  Future<List> getFriends() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/friends/get_friend'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get friends error: $e');
      return [];
    }
  }

  /// POST /users/friends/{user_id}
  Future<bool> addFriend(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/friends/post_friend/$userId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Add friend error: $e');
      return false;
    }
  }

  /// DELETE /users/friends/{user_id}
  Future<bool> removeFriend(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/friends/delete_friend/$userId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Remove friend error: $e');
      return false;
    }
  }

  /// POST /users/friends/phone
  Future<Map<String, dynamic>?> addFriendByPhone(String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/friends/phone'),
            headers: headers,
            body: jsonEncode({'phone': phone}),
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Add friend by phone error: $e');
      return null;
    }
  }

  /// GET /users/friends/search?query={name}
  Future<List> searchFriends(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/friends/search?query=${Uri.encodeComponent(query)}'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Search friends error: $e');
      return [];
    }
  }

  // ============ BADGES ============

  /// GET /users/me/badges
  Future<List> getBadges() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_my_badges'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get badges error: $e');
      return [];
    }
  }

  /// POST /users/me/badges/{badge_id}/claim
  Future<bool> claimBadge(String badgeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/post_my_badges/$badgeId/claim'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Claim badge error: $e');
      return false;
    }
  }

  // ============ PHOTO UPLOADS - ✅ NEW ============

  /// POST /users/restaurants/{restaurant_id}/photos
  Future<bool> uploadRestaurantPhoto(
      String restaurantId, Map<String, dynamic> photoData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants/$restaurantId/photos'),
            headers: headers,
            body: jsonEncode(photoData),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Upload restaurant photo error: $e');
      return false;
    }
  }

  /// POST /users/beverages/{beverage_id}/photos
  Future<bool> uploadBeveragePhoto(
      String beverageId, Map<String, dynamic> photoData) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/beverages/$beverageId/photos'),
            headers: headers,
            body: jsonEncode(photoData),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Upload beverage photo error: $e');
      return false;
    }
  }

  // ============ HEALTH CHECK ============

  /// GET /users/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check error: $e');
      return false;
    }
  }
}
