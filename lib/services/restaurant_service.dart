// lib/services/restaurant_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../../features/models/restaurant_model.dart';

class RestaurantService {
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

  // ============ RESTAURANTS ============

  /// GET /users/restaurants
  /// GET /users/restaurants
  Future<List<Map<String, dynamic>>> getRestaurants({
    String? city,
    double? lat,
    double? lon,
    double? radius,
    String? search,
    String? cuisine,
    double? minRating,
    double? maxDistance,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{};

      if (city != null) params['city'] = city;
      if (lat != null) params['lat'] = lat.toString();
      if (lon != null) params['lon'] = lon.toString();
      if (radius != null) params['radius'] = radius.toString();
      if (search != null) params['search'] = search;
      if (cuisine != null) params['cuisine'] = cuisine;
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (maxDistance != null) params['max_distance'] = maxDistance.toString();
      if (sortBy != null) params['sort_by'] = sortBy;

      final uri =
          Uri.parse('$baseUrl/restaurants').replace(queryParameters: params);

      final response = await http
          .get(uri, headers: headers)
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        // Fallback for direct array response
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Get restaurants error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/featured
  Future<List<Map<String, dynamic>>> getFeaturedRestaurants() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/featured'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Get featured restaurants error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/trending
  Future<List<Map<String, dynamic>>> getTrendingRestaurants() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/trending'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Get trending restaurants error: $e');
      return [];
    }
  }

  /// GET /restaurants/{restaurant_id}
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return Restaurant.fromJson(body['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Get restaurant error: $e');
      return null;
    }
  }

  /// GET /users/restaurants/by-city
  Future<List> getRestaurantsByCity(String city) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/restaurants/by-city?city=${Uri.encodeComponent(city)}'),
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
      print('❌ Get restaurants by city error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/nearby
  Future<List> getNearbyRestaurants({
    required double lat,
    required double lon,
    double radius = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/restaurants/nearby?lat=$lat&lon=$lon&radius=$radius'),
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
      print('❌ Get nearby restaurants error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/{restaurant_id}/beverages
  Future<List> getRestaurantBeverages(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/beverages'),
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
      print('❌ Get restaurant beverages error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/{restaurant_id}/events
  Future<List> getRestaurantEvents(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/events'),
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
      print('❌ Get restaurant events error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/{restaurant_id}/ratings
  Future<List> getRestaurantRatings(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/ratings'),
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
      print('❌ Get restaurant ratings error: $e');
      return [];
    }
  }

  /// POST /users/restaurants/{restaurant_id}/rate
  Future<bool> rateRestaurant(
      String restaurantId, Map<String, dynamic> rating) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/restaurants/$restaurantId/rate'),
            headers: headers,
            body: jsonEncode(rating),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Rate restaurant error: $e');
      return false;
    }
  }

  /// GET /users/restaurants/{restaurant_id}/menu-photos
  Future<List> getMenuPhotos(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/menu-photos'),
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
      print('❌ Get menu photos error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/{restaurant_id}/food-gallery
  Future<List> getFoodGallery(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/food-gallery'),
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
      print('❌ Get food gallery error: $e');
      return [];
    }
  }

  /// GET /users/restaurants/{restaurant_id}/expert-recommendations
  Future<List> getExpertRecommendations(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/restaurants/$restaurantId/expert-recommendations'),
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
      print('❌ Get expert recommendations error: $e');
      return [];
    }
  }
}
