// lib/services/expert_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class ExpertService {
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

  // ============ EXPERTS ============

  /// GET /users/experts
  Future<List> getExperts() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/experts'),
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
      print('❌ Get experts error: $e');
      return [];
    }
  }

  /// GET /users/experts/{expert_id}
  Future<Map<String, dynamic>?> getExpert(String expertId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/experts/$expertId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get expert error: $e');
      return null;
    }
  }

  /// GET /users/experts/{expert_id}/ratings
  Future<List> getExpertRatings(String expertId, {int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/experts/$expertId/ratings?limit=$limit'),
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
      print('❌ Get expert ratings error: $e');
      return [];
    }
  }

  /// GET /users/experts/{expert_id}/breakdown/{beverage_id}
  Future<Map<String, dynamic>?> getExpertBreakdown(
      String expertId, String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/experts/$expertId/breakdown/$beverageId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get expert breakdown error: $e');
      return null;
    }
  }

  /// GET /users/experts/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/experts/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Experts health check error: $e');
      return false;
    }
  }
}
