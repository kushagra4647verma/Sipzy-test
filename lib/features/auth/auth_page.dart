import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme/colors.dart';
import '../core/theme/radius.dart';

enum AuthStep { phone, otp, signup }

class AuthPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onLogin;

  const AuthPage({super.key, required this.onLogin});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const API = String.fromEnvironment('API_URL');

  AuthStep step = AuthStep.phone;

  String phone = '';
  String otp = '';
  String displayOtp = '';
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
      final res = await http.post(
        Uri.parse('$API/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(res.body);
      setState(() {
        displayOtp = data['otp'].toString();
        step = AuthStep.otp;
      });

      _toast('OTP sent! Your OTP is: ${data['otp']}');
    } catch (_) {
      _toast('Failed to send OTP', error: true);
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
      final res = await http.post(
        Uri.parse('$API/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final data = jsonDecode(res.body);

      if (data['is_new'] == true) {
        setState(() => step = AuthStep.signup);
      } else {
        widget.onLogin(data['user']);
        _toast('Welcome back!');
      }
    } catch (_) {
      _toast('Invalid OTP. Please try again.', error: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> signup() async {
    if (name.isEmpty || age.isEmpty) {
      _toast('Please fill in all fields', error: true);
      return;
    }

    if (int.tryParse(age)! < 23) {
      _toast('You must be 23 years or older to use SipZy', error: true);
      return;
    }

    if (!agreedToTerms) {
      _toast('Please agree to the Terms & Conditions', error: true);
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse('$API/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'age': int.parse(age), 'phone': phone}),
      );

      final data = jsonDecode(res.body);
      widget.onLogin(data['user']);
      _toast('Welcome to SipZy!');
    } catch (e) {
      _toast('Failed to create account', error: true);
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
          'Welcome!',
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
            counterText: '',
          ),
        ),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : sendOtp,
          child: Text(loading ? 'Sending…' : 'Send OTP'),
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
        Text('Enter the 6-digit code sent to $phone'),

        if (displayOtp.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Your OTP: $displayOtp',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
          ),

        TextField(
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (v) => otp = v,
          decoration: const InputDecoration(labelText: 'OTP'),
        ),

        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: loading ? null : verifyOtp,
          child: Text(loading ? 'Verifying…' : 'Verify OTP'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              step = AuthStep.phone;
              otp = '';
              displayOtp = '';
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
        ElevatedButton(
          onPressed: loading ? null : signup,
          child: Text(loading ? 'Creating Account…' : 'Get Started'),
        ),
      ],
    );
  }
}
