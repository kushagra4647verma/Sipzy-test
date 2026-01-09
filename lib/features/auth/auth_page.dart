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

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.primary,
      ),
    );
  }

  Future<void> sendOtp() async {
    if (phone.length != 10) {
      _toast('Please enter a valid 10-digit phone number', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('📱 Sending OTP to: +91$phone');
      final result = await _authService.sendOtp(phone);
      print('✅ Send OTP Response: $result');

      if (result['success']) {
        setState(() => step = AuthStep.otp);
        _toast('OTP sent to your phone!');
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
    if (otp.length != 6) {
      _toast('Please enter the complete 6-digit OTP', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('🔐 Verifying OTP: $otp for phone: +91$phone');
      final result = await _authService.verifyOtp(phone, otp);
      print('✅ Verify OTP Response: $result');

      if (result['success']) {
        if (result['is_new'] == true) {
          setState(() => step = AuthStep.signup);
        } else {
          // Pass both user and token
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
    if (name.isEmpty || age.isEmpty) {
      _toast('Please fill in all fields', error: true);
      return;
    }

    final ageInt = int.tryParse(age);
    if (ageInt == null || ageInt < 23) {
      _toast('You must be 23 years or older to use SipZy', error: true);
      return;
    }

    if (!agreedToTerms) {
      _toast('Please agree to the Terms & Conditions', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print('👤 Signing up: $name, age: $ageInt, phone: +91$phone');
      final result = await _authService.signUp(
        name: name,
        age: ageInt,
        phone: phone,
      );
      print('✅ Signup Response: $result');

      if (result['success']) {
        // Pass both user and token
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
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: (v) => phone = v.replaceAll(RegExp(r'\D'), ''),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+91 ',
            counterText: '',
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
        const SizedBox(height: 24),
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (v) => otp = v,
          decoration: const InputDecoration(
            labelText: 'OTP',
            counterText: '',
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
            });
          },
          child: const Text('Change Phone Number'),
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
          decoration: const InputDecoration(labelText: 'Full Name'),
          onChanged: (v) => name = v,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(labelText: 'Age (23+)'),
          keyboardType: TextInputType.number,
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
