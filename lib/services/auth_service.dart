// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  /// Send OTP via Supabase Auth (triggers backend SMS hook)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      print('📱 Sending OTP to: +91$phone');

      await _supabase.auth.signInWithOtp(
        phone: '+91$phone',
      );

      print('✅ OTP request sent to Supabase');

      // In development mode, fetch the OTP from backend
      if (EnvConfig.isDevelopment) {
        await Future.delayed(
            const Duration(seconds: 2)); // Wait for OTP to be stored

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
      final url = '${EnvConfig.authDevOtp}/$phone';
      print('🔍 Fetching dev OTP from: $url');

      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Dev OTP Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['otp']?.toString();
      } else {
        print('⚠️ Dev OTP endpoint returned: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to get dev OTP: $e');
    }
    return null;
  }

  /// Verify OTP via Supabase Auth
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      print('🔐 Verifying OTP: $otp for phone: +91$phone');

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

        print('✅ OTP Verified - User ID: ${user.id}');

        // Check if profile exists
        final profile = await _getUserProfile(user.id);

        // User is new if profile doesn't exist OR if profile has no name
        final isNew = profile == null ||
            profile['name'] == null ||
            profile['name'].toString().isEmpty;

        print('🔍 Profile check - User ID: ${user.id}, Is new: $isNew');

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

  /// Get user profile from profiles table
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
          .upsert(profileData)
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

  /// Get current user
  Map<String, dynamic>? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    return {
      'id': user.id,
      'phone': user.phone,
      'email': user.email,
    };
  }

  /// Get current session token
  String? getCurrentToken() {
    return _supabase.auth.currentSession?.accessToken;
  }
}
