// lib/services/beverage_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class BeverageService {
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

  // ============ BEVERAGES ============

  /// GET /users/beverages
  Future<List> getBeverages() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages'),
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
      print('❌ Get beverages error: $e');
      return [];
    }
  }

  /// GET /users/beverages/{beverage_id}
  Future<Map<String, dynamic>?> getBeverage(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get beverage error: $e');
      return null;
    }
  }

  /// GET /users/beverages/{beverage_id}/ratings
  Future<List> getBeverageRatings(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId/ratings'),
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
      print('❌ Get beverage ratings error: $e');
      return [];
    }
  }

  /// POST /users/beverages/{beverage_id}/rate
  Future<bool> rateBeverage(
      String beverageId, Map<String, dynamic> rating) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/beverages/$beverageId/rate'),
            headers: headers,
            body: jsonEncode(rating),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Rate beverage error: $e');
      return false;
    }
  }

  /// GET /users/beverages/{beverage_id}/photos
  Future<List> getBeveragePhotos(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId/photos'),
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
      print('❌ Get beverage photos error: $e');
      return [];
    }
  }
}
