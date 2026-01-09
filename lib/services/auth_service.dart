// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      // Using Supabase Auth for OTP
      final response = await _supabase.auth.signInWithOtp(
        phone: '+91$phone', // Assuming Indian numbers
        shouldCreateUser: true,
      );

      return {
        'success': true,
        'message': 'OTP sent successfully',
        // For development, you might want to show OTP
        // In production, this should NOT be returned
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: '+91$phone',
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null) {
        // Check if user profile exists
        final profile = await _getUserProfile(response.user!.id);

        return {
          'success': true,
          'is_new': profile == null,
          'user': profile ?? {'id': response.user!.id, 'phone': phone},
          'session': response.session,
        };
      }

      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String name,
    required int age,
    required String phone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Create user profile in database
      final response = await http.post(
        Uri.parse('${ApiService.userService}/profile'),
        headers: ApiService.getUserHeaders(userId),
        body: jsonEncode({
          'name': name,
          'age': age,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data['data'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to create profile',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.userService}/me'),
        headers: ApiService.getUserHeaders(userId),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current session
  Future<Session?> getCurrentSession() async {
    return _supabase.auth.currentSession;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
