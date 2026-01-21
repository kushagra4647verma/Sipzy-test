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
  /// ✅ FIXED: Using correct endpoint format matching working frontend
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      // Clean and format phone number
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = '+91$cleanPhone';

      print('📱 Sending OTP to: $fullPhone');

      // ✅ FIXED: Direct HTTP call to match working frontend
      final response = await http
          .post(
            Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/otp'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': EnvConfig.supabaseAnonKey,
            },
            body: jsonEncode({
              'phone': fullPhone,
              'create_user': true,
            }),
          )
          .timeout(EnvConfig.requestTimeout);

      print('📱 OTP Response Status: ${response.statusCode}');
      print('📱 OTP Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // In dev mode, fetch the OTP from backend
        if (USE_DEV_MODE) {
          await Future.delayed(
              const Duration(seconds: 2)); // Wait for OTP to be stored

          try {
            final devOtp = await _getDevOtp(fullPhone);
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
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['msg'] ?? errorData['message'] ?? 'Failed to send OTP',
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

  /// Fetch OTP from dev endpoint (only works in development)
  /// ✅ FIXED: Using correct URL encoding format
  Future<String?> _getDevOtp(String fullPhone) async {
    try {
      // URL encode the phone number with + sign
      final encodedPhone = Uri.encodeComponent(fullPhone);

      print('🔧 Fetching dev OTP for: $encodedPhone');

      // Your backend's dev endpoint
      final response = await http
          .get(
            Uri.parse('${EnvConfig.apiBaseUrl}/auth/dev-otp/$encodedPhone'),
          )
          .timeout(EnvConfig.requestTimeout);

      print('🔧 Dev OTP Response Status: ${response.statusCode}');
      print('🔧 Dev OTP Response Body: ${response.body}');

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
  /// ✅ FIXED: Using correct verification endpoint
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      // Clean and format phone number
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = '+91$cleanPhone';

      print('🔐 Verifying OTP: $otp for phone: $fullPhone');

      // ✅ FIXED: Direct HTTP call to match working frontend
      final response = await http
          .post(
            Uri.parse('${EnvConfig.supabaseUrl}/auth/v1/verify'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': EnvConfig.supabaseAnonKey,
            },
            body: jsonEncode({
              'type': 'sms',
              'phone': fullPhone,
              'token': otp,
            }),
          )
          .timeout(EnvConfig.requestTimeout);

      print('🔐 Verify Response Status: ${response.statusCode}');
      print('🔐 Verify Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['user'];
        final session =
            data['access_token'] ?? data['session']?['access_token'];

        if (user == null || session == null) {
          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }

        // Set the session in Supabase client
        await _supabase.auth.recoverSession(response.body);

        // ✅ CRITICAL FIX: Check if profile exists
        final profile = await _getUserProfile(user['id']);

        // ✅ User is new if profile doesn't exist OR if profile has no name
        final isNew = profile == null ||
            profile['name'] == null ||
            profile['name'].toString().isEmpty;

        print(
            '🔍 Profile check - User ID: ${user['id']}, Profile exists: ${profile != null}, Is new: $isNew');

        return {
          'success': true,
          'is_new': isNew,
          'user': isNew
              ? {
                  'id': user['id'],
                  'phone': user['phone'],
                }
              : profile,
          'token': session,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['msg'] ?? errorData['message'] ?? 'Invalid OTP',
        };
      }
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

      // Clean phone number for storage
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = '+91$cleanPhone';

      // Create user profile in profiles table
      final profileData = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': fullPhone,
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
