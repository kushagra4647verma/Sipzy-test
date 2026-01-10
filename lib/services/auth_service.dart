// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Toggle this for production
  static const bool USE_DEV_MODE = true;

  /// Send OTP via Supabase Auth (uses MessageBot)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: '+91$phone',
      );

      print('📱 OTP sent to +91$phone');

      // In dev mode, fetch the OTP from backend
      if (USE_DEV_MODE) {
        await Future.delayed(
            const Duration(seconds: 1)); // Wait for OTP to be stored

        try {
          final devOtp = await _getDevOtp(phone);
          if (devOtp != null) {
            print('🔧 DEV OTP retrieved: $devOtp');
            return {
              'success': true,
              'message': 'OTP sent successfully',
              'dev_otp': devOtp,
            };
          }
        } catch (e) {
          print('⚠️ Could not fetch dev OTP: $e');
        }
      }

      return {
        'success': true,
        'message': 'OTP sent successfully',
      };
    } on AuthException catch (e) {
      print('❌ Supabase Auth Error: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ Send OTP Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Fetch OTP from dev endpoint (only works in development)
  Future<String?> _getDevOtp(String phone) async {
    try {
      // Your backend's dev endpoint
      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/auth/dev-otp/91$phone'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['otp']?.toString();
      }
    } catch (e) {
      print('Failed to get dev OTP: $e');
    }
    return null;
  }

  /// Verify OTP via Supabase Auth
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: '+91$phone',
        token: otp,
      );

      if (response.session != null) {
        final user = response.user;
        final profile = await _getUserProfile(user!.id);
        final isNew = profile == null;

        return {
          'success': true,
          'is_new': isNew,
          'user': isNew
              ? {
                  'id': user.id,
                  'phone': user.phone,
                }
              : profile,
          'token': response.session!.accessToken,
        };
      }

      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } on AuthException catch (e) {
      print('❌ Verify OTP Error: ${e.message}');
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      print('❌ Verification Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user profile from custom users table
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Profile not found for user $userId');
      return null;
    }
  }

  /// Sign up new user with profile data
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
          'message': 'No authenticated user found',
        };
      }

      // Create user profile in your custom users table
      final response = await _supabase
          .from('profiles')
          .insert({
            'id': userId,
            'name': name,
            'phone': phone,
          })
          .select()
          .single();

      return {
        'success': true,
        'user': response,
        'token': _supabase.auth.currentSession?.accessToken,
      };
    } catch (e) {
      print('❌ Signup Error: $e');
      return {
        'success': false,
        'message': 'Failed to create profile: ${e.toString()}',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
