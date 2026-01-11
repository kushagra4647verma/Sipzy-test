// lib/features/auth/auth_page.dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../services/auth_service.dart';

enum AuthStep { phone, otp, signup }

class AuthPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;

  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _authService = AuthService();

  AuthStep step = AuthStep.phone;

  String phone = '';
  String otp = '';
  String name = '';
  String age = '';
  bool agreedToTerms = false;
  bool loading = false;

  // Store dev OTP to display it
  String? devOtp;

  // Text controllers for clearing fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.primary,
      ),
    );
  }

  Future<void> sendOtp() async {
    // Validate phone number
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.isEmpty) {
      _toast('Please enter a phone number', error: true);
      return;
    }

    if (cleanPhone.length != 10) {
      _toast('Please enter a valid 10-digit phone number', error: true);
      return;
    }

    // Check if it starts with valid Indian mobile prefix
    if (!RegExp(r'^[6-9]').hasMatch(cleanPhone)) {
      _toast('Phone number must start with 6, 7, 8, or 9', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('📱 Sending OTP to: +91$cleanPhone');
      final result = await _authService.sendOtp(cleanPhone);
      print('✅ Send OTP Response: $result');

      if (result['success']) {
        setState(() {
          phone = cleanPhone; // Store cleaned phone
          step = AuthStep.otp;
          devOtp = result['dev_otp']; // Store dev OTP if available
          otp = ''; // Clear OTP value
          _otpController.clear(); // Clear OTP field for fresh input
        });

        if (devOtp != null) {
          _toast('DEV MODE: OTP is $devOtp');
        } else {
          _toast('OTP sent! Check DigitalOcean logs');
        }
      } else {
        _toast(result['message'] ?? 'Failed to send OTP', error: true);
      }
    } catch (e) {
      print('❌ Send OTP Exception: $e');
      _toast('Failed to send OTP: ${e.toString()}', error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> verifyOtp() async {
    // Validate OTP
    final cleanOtp = otp.replaceAll(RegExp(r'\D'), '');

    if (cleanOtp.isEmpty) {
      _toast('Please enter the OTP', error: true);
      return;
    }

    if (cleanOtp.length != 6) {
      _toast('Please enter the complete 6-digit OTP', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('🔐 Verifying OTP: $cleanOtp for phone: +91$phone');
      final result = await _authService.verifyOtp(phone, cleanOtp);
      print('✅ Verify OTP Response: $result');

      if (result['success']) {
        if (result['is_new'] == true) {
          setState(() {
            step = AuthStep.signup;
            _nameController.clear(); // Clear signup fields
            _ageController.clear();
          });
        } else {
          widget.onLogin({
            'user': result['user'],
            'token': result['token'],
          });
          _toast('Welcome back!');
        }
      } else {
        _toast(result['message'] ?? 'Invalid OTP', error: true);
      }
    } catch (e) {
      print('❌ Verify OTP Exception: $e');
      _toast('Verification failed: ${e.toString()}', error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> signup() async {
    // Validate all fields
    final trimmedName = name.trim();
    final trimmedAge = age.trim();

    if (trimmedName.isEmpty) {
      _toast('Please enter your full name', error: true);
      return;
    }

    if (trimmedName.length < 2) {
      _toast('Name must be at least 2 characters', error: true);
      return;
    }

    if (trimmedAge.isEmpty) {
      _toast('Please enter your age', error: true);
      return;
    }

    final ageInt = int.tryParse(trimmedAge);
    if (ageInt == null) {
      _toast('Please enter a valid age', error: true);
      return;
    }

    if (ageInt < 23) {
      _toast('You must be 23 years or older to use SipZy', error: true);
      return;
    }

    if (ageInt > 120) {
      _toast('Please enter a valid age', error: true);
      return;
    }

    if (!agreedToTerms) {
      _toast('Please agree to the Terms & Conditions', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('👤 Signing up: $trimmedName, age: $ageInt, phone: +91$phone');
      final result = await _authService.signUp(
        name: trimmedName,
        age: ageInt,
        phone: phone,
      );
      print('✅ Signup Response: $result');

      if (result['success']) {
        widget.onLogin({
          'user': result['user'],
          'token': result['token'],
        });
        _toast('Welcome to SipZy!');
      } else {
        _toast(result['message'] ?? 'Failed to create account', error: true);
      }
    } catch (e) {
      print('❌ Signup Exception: $e');
      _toast('Signup failed: ${e.toString()}', error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            width: 380,
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case AuthStep.phone:
        return _phoneStep();
      case AuthStep.otp:
        return _otpStep();
      case AuthStep.signup:
        return _signupStep();
    }
  }

  Widget _phoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to SipZy!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Enter your phone number to get started'),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: (v) => phone = v.replaceAll(RegExp(r'\D'), ''),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+91 ',
            counterText: '',
            helperText: 'Enter 10-digit mobile number',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : sendOtp,
            child: Text(loading ? 'Sending…' : 'Send OTP'),
          ),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify OTP',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Enter the 6-digit code sent to +91 $phone'),

        // Show dev OTP prominently
        if (devOtp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.bug_report, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'DEV MODE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your OTP: $devOtp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'From DigitalOcean Backend',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          onChanged: (v) {
            otp = v.replaceAll(RegExp(r'\D'), '');
          },
          decoration: const InputDecoration(
            labelText: 'OTP',
            counterText: '',
            helperText: 'Enter the 6-digit code',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : verifyOtp,
            child: Text(loading ? 'Verifying…' : 'Verify OTP'),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              step = AuthStep.phone;
              otp = '';
              devOtp = null;
              _otpController.clear();
            });
          },
          child: const Text('Change Phone Number'),
        ),
        TextButton(
          onPressed: loading ? null : sendOtp,
          child: const Text('Resend OTP'),
        ),
      ],
    );
  }

  Widget _signupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            helperText: 'Enter your full name',
          ),
          onChanged: (v) => name = v,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(
            labelText: 'Age (23+)',
            helperText: 'You must be 23 or older',
          ),
          keyboardType: TextInputType.number,
          maxLength: 3,
          onChanged: (v) => age = v,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: agreedToTerms,
          onChanged: (v) => setState(() => agreedToTerms = v ?? false),
          title: const Text(
            'I agree to the Terms & Conditions and confirm I am 23+',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : signup,
            child: Text(loading ? 'Creating Account…' : 'Get Started'),
          ),
        ),
      ],
    );
  }
}
