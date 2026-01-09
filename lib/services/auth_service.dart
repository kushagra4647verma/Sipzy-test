// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class AuthService {
  // Your backend's auth/OTP endpoints
  static const String authBaseUrl = '${EnvConfig.apiBaseUrl}/auth';

  /// Send OTP via backend (which uses Twilio)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$authBaseUrl/send-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'country_code': '+91',
            }),
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      print('❌ Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify OTP via backend
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$authBaseUrl/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'country_code': '+91',
              'otp': otp,
            }),
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend should return:
        // {
        //   "success": true,
        //   "is_new": false,
        //   "user": {...},
        //   "token": "jwt_token"
        // }

        return {
          'success': true,
          'is_new': data['is_new'] ?? false,
          'user': data['user'],
          'token': data['token'],
        };
      } else if (response.statusCode == 404) {
        // User not found - needs signup
        return {
          'success': true,
          'is_new': true,
          'phone': phone,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      print('❌ Verify OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String name,
    required int age,
    required String phone,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$authBaseUrl/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'age': age,
              'phone': phone,
              'country_code': '+91',
            }),
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create account',
        };
      }
    } catch (e) {
      print('❌ Signup Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get current user profile (if you need to refresh user data)
  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$authBaseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print('❌ Get Profile Error: $e');
      return null;
    }
  }

  /// Sign out (clear local session - add backend logout if needed)
  Future<void> signOut() async {
    // If your backend has a logout endpoint:
    // await http.post(Uri.parse('$authBaseUrl/logout'));

    // Clear local session (handled by AuthState)
  }
}
