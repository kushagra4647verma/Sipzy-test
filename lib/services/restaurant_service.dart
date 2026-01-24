// lib/services/restaurant_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../../features/models/restaurant_model.dart';
import 'dart:typed_data';
import 'location_service.dart';

class RestaurantService {
  final _supabase = Supabase.instance.client;
  final _locationService = LocationService();
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

  // ============ WKB PARSING ============
  Map<String, double>? _parseLocationGeometry(String? wkb) {
    if (wkb == null || wkb.isEmpty) return null;

    try {
      // PostGIS WKB format for POINT with SRID:
      // - Byte order (1 byte): 01
      // - WKB type (4 bytes): 01000020
      // - SRID (4 bytes): E6100000 (4326 in little-endian)
      // - X coordinate/Longitude (8 bytes)
      // - Y coordinate/Latitude (8 bytes)

      if (wkb.length < 50) {
        print('⚠️ WKB too short: ${wkb.length}');
        return null;
      }

      // Extract hex strings for coordinates (skip first 18 chars = 9 bytes)
      final lonHex = wkb.substring(18, 34); // 8 bytes = 16 hex chars
      final latHex = wkb.substring(34, 50); // 8 bytes = 16 hex chars

      // Convert hex to bytes
      final lonBytes = _hexToBytes(lonHex);
      final latBytes = _hexToBytes(latHex);

      // Convert bytes to double (little-endian)
      final lon = _bytesToDouble(lonBytes);
      final lat = _bytesToDouble(latBytes);

      print('📍 Parsed WKB: lat=$lat, lon=$lon');

      return {'lat': lat, 'lon': lon};
    } catch (e) {
      print('❌ Error parsing WKB: $e');
      return null;
    }
  }

  // Helper: Convert hex string to bytes
  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  double _bytesToDouble(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    return byteData.getFloat64(0, Endian.little);
  }

  /// ✅ FIXED: Calculate distance for restaurant
  void _calculateDistanceForRestaurant(
    Map<String, dynamic> restaurant,
    double? userLat,
    double? userLon,
  ) {
    try {
      // First parse WKB location if it exists
      if (restaurant['location'] != null) {
        final coords = _parseLocationGeometry(restaurant['location']);
        if (coords != null) {
          restaurant['lat'] = coords['lat'];
          restaurant['lon'] = coords['lon'];
          restaurant['latitude'] = coords['lat'];
          restaurant['longitude'] = coords['lon'];
        }
      }

      // ✅ FIXED: Try multiple field names for coordinates
      final lat = restaurant['lat'] ??
          restaurant['latitude'] ??
          restaurant['restaurantLatitude'];
      final lon = restaurant['lon'] ??
          restaurant['longitude'] ??
          restaurant['restaurantLongitude'];

      // Calculate distance if we have both user and restaurant coordinates
      if (userLat != null && userLon != null && lat != null && lon != null) {
        final restaurantLat =
            lat is num ? lat.toDouble() : double.parse(lat.toString());
        final restaurantLon =
            lon is num ? lon.toDouble() : double.parse(lon.toString());

        final distance = _locationService.calculateDistance(
          userLat,
          userLon,
          restaurantLat,
          restaurantLon,
        );

        restaurant['distance'] = distance;
        print(
            '✅ Calculated distance for ${restaurant['name']}: ${distance.toStringAsFixed(2)} km');
      } else {
        // Set default distance if coordinates are missing
        restaurant['distance'] = 0.0;
        print(
            '⚠️ Missing coordinates for ${restaurant['name']} - lat: $lat, lon: $lon, userLat: $userLat, userLon: $userLon');
      }
    } catch (e) {
      print('❌ Error calculating distance for ${restaurant['name']}: $e');
      restaurant['distance'] = 0.0;
    }
  }

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

      print('🌐 Fetching restaurants from: $uri');
      print('📍 User location: lat=$lat, lon=$lon');

      final response = await http
          .get(uri, headers: headers)
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Fetched ${restaurants.length} restaurants');

          // ✅ Calculate distance for each restaurant
          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }

          return restaurants;
        }

        // Fallback for direct array response
        if (data is List) {
          final restaurants = List<Map<String, dynamic>>.from(data);
          print('✅ Fetched ${restaurants.length} restaurants (direct array)');

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }

          return restaurants;
        }
      }

      print('⚠️ No restaurants found or invalid response');
      return [];
    } catch (e) {
      print('❌ Get restaurants error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFeaturedRestaurants({
    double? lat,
    double? lon,
  }) async {
    try {
      if (lat == null || lon == null) {
        print('⚠️ Location not available for featured restaurants');
        return [];
      }

      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/featured/$lat/$lon'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      print('🔥 Featured Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(decoded['data']);

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }

          return restaurants;
        }
      } else if (response.statusCode == 404) {
        print(
            '⚠️ Featured endpoint not found - feature may not be implemented');
      }

      return [];
    } catch (e) {
      print('❌ Get featured restaurants error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingRestaurants({
    required String city,
  }) async {
    try {
      final headers = await _getHeaders();
      final encodedCity = Uri.encodeComponent(city);
      final position = await _locationService.getCurrentLocation();

      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/trending/$encodedCity'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      print('📈 Trending Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Handle null response
        if (decoded == null) {
          print('⚠️ Trending returned null');
          return [];
        }

        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(decoded['data']);

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(
              restaurant,
              position?.latitude,
              position?.longitude,
            );
          }

          return restaurants;
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
          final restaurantData = body['data'] as Map<String, dynamic>;

          // ✅ Get user location for distance calculation
          final position = await _locationService.getCurrentLocation();

          // Calculate distance
          _calculateDistanceForRestaurant(
            restaurantData,
            position?.latitude,
            position?.longitude,
          );

          return Restaurant.fromJson(restaurantData);
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
      final position = await _locationService.getCurrentLocation();

      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/restaurants/by-city?city=${Uri.encodeComponent(city)}'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurants = data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);

        // ✅ Calculate distances
        for (var restaurant in restaurants) {
          _calculateDistanceForRestaurant(
            restaurant as Map<String, dynamic>,
            position?.latitude,
            position?.longitude,
          );
        }

        return restaurants;
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
        final restaurants = data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);

        // ✅ Calculate distances
        for (var restaurant in restaurants) {
          _calculateDistanceForRestaurant(
            restaurant as Map<String, dynamic>,
            lat,
            lon,
          );
        }

        return restaurants;
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
