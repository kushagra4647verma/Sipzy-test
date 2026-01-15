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

        if (user == null) {
          return {
            'success': false,
            'message': 'No user returned from verification',
          };
        }

        // ✅ CRITICAL FIX: Check if profile exists
        final profile = await _getUserProfile(user.id);

        // ✅ User is new if profile doesn't exist OR if profile has no name
        final isNew = profile == null ||
            profile['name'] == null ||
            profile['name'].toString().isEmpty;

        print(
            '🔍 Profile check - User ID: ${user.id}, Profile exists: ${profile != null}, Is new: $isNew');

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
  /// ✅ FIX: Added better error handling and null checks
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      print('🔍 Checking profile for user: $userId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        print('✅ No profile found - user is new');
        return null;
      }

      print('✅ Profile found: ${response['name']}');
      return response;
    } catch (e) {
      print('⚠️ Error fetching profile for user $userId: $e');
      // If there's an error fetching profile, assume user is new
      return null;
    }
  }

  /// Sign up new user with comprehensive profile data
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String dob,
    required String city,
    required String phone,
    bool enableLocation = false,
    bool enableNotifications = false,
    bool enableSocialFeatures = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        return {
          'success': false,
          'message': 'No authenticated user found',
        };
      }

      print('📝 Creating profile for user: $userId');

      // Create user profile in profiles table
      final profileData = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
      };

      final response = await _supabase
          .from('profiles')
          .upsert(profileData) // ✅ Changed to upsert to handle any edge cases
          .select()
          .single();

      print('✅ Profile created successfully');

      // Store additional metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'dob': dob,
            'city': city.isNotEmpty ? city : null,
            'enableLocation': enableLocation,
            'enableNotifications': enableNotifications,
            'enableSocialFeatures': enableSocialFeatures,
            'onboarding_completed': true,
          },
        ),
      );

      print('✅ User metadata updated');

      return {
        'success': true,
        'user': {
          ...response,
          'dob': dob,
          'city': city,
        },
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
