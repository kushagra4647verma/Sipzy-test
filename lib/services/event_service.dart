// lib/services/event_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class EventService {
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

  // ============ EVENTS ============

  /// GET /users/events
  Future<List> getEvents({String? restaurantId}) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{};

      if (restaurantId != null) {
        params['restaurant_id'] = restaurantId;
      }

      final uri = Uri.parse('$baseUrl/events')
          .replace(queryParameters: params.isEmpty ? null : params);

      final response = await http
          .get(uri, headers: headers)
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get events error: $e');
      return [];
    }
  }

  /// GET /users/events/{event_id}
  Future<Map<String, dynamic>?> getEvent(String eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/events/$eventId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get event error: $e');
      return null;
    }
  }

  /// GET /users/events/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/events/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Events health check error: $e');
      return false;
    }
  }
}
