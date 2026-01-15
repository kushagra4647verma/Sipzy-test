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
  final FocusNode _otpFocusNode = FocusNode();
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
    _otpFocusNode.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _logo(),
                const SizedBox(height: 32),
                _authCard(),
                const SizedBox(height: 16),
                _termsText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _termsText() {
    return const Text(
      "By continuing, you agree to SipZy's Terms of Service and Privacy Policy",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white38,
        fontSize: 12,
      ),
    );
  }

  Widget _authCard() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: _buildStep(),
    );
  }

  Widget _logo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.local_drink, color: AppColors.primary, size: 36),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Sip', style: TextStyle(color: Color(0xFFF5B642))),
              TextSpan(text: 'Zy', style: TextStyle(color: Color(0xFF9B6BFF))),
            ],
          ),
        ),
      ],
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
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your phone number to get started',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Row(
          children: const [
            Icon(Icons.phone, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'Phone Number',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          onChanged: (v) => phone = v.replaceAll(RegExp(r'\D'), ''),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            counterText: '',
            hintText: '10-digit phone number',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF3A3A3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5B642),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              loading ? 'Sending OTP…' : 'Send OTP',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 6-digit code sent to $phone',
          style: const TextStyle(color: Colors.white70),
        ),

        /// DEV OTP DISPLAY
        if (devOtp != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Your OTP:  $devOtp',
                style: const TextStyle(
                  color: Color(0xFFF5B642),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        /// OTP BOXES
        _otpBoxes(),

        const SizedBox(height: 24),

        /// VERIFY BUTTON
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5B642),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              loading ? 'Verifying…' : 'Verify OTP',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                step = AuthStep.phone;
                otp = '';
                devOtp = null;
                _otpController.clear();
              });
            },
            child: const Text(
              'Change Phone Number',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _otpBoxes() {
    return GestureDetector(
      onTap: () => _otpFocusNode.requestFocus(),
      child: Column(
        children: [
          /// VISIBLE OTP BOXES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final char = index < otp.length ? otp[index] : '';
              final isActive =
                  otp.length < 6 ? index == otp.length : index == 5;

              return Container(
                width: 46,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isActive ? const Color(0xFFF5B642) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  char,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),

          /// HIDDEN TEXTFIELD (REAL INPUT)
          SizedBox(
            height: 0,
            width: 0,
            child: TextField(
              focusNode: _otpFocusNode,
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              onChanged: (v) {
                otp = v.replaceAll(RegExp(r'\D'), '');
                setState(() {});

                if (otp.length == 6 && !loading) {
                  verifyOtp();
                }
              },
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
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
