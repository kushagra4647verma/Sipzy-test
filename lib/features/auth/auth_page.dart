// lib/features/auth/auth_page.dart
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
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
  String email = '';
  String dob = '';
  String city = '';
  bool enableLocation = false;
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;
  bool confirmedAge = false;
  bool confirmedAlcoholConsent = false;
  bool enableNotifications = false;
  bool enableSocialFeatures = false;
  bool loading = false;

  // Store dev OTP to display it
  String? devOtp;

  // Text controllers for clearing fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();

  // Indian cities list
  final List<String> _indianCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Surat',
    'Lucknow',
    'Kanpur',
    'Nagpur',
    'Indore',
    'Thane',
    'Bhopal',
    'Visakhapatnam',
    'Pimpri-Chinchwad',
    'Patna',
    'Vadodara',
    'Ghaziabad',
    'Ludhiana',
    'Agra',
    'Nashik',
    'Faridabad',
    'Meerut',
    'Rajkot',
    'Kalyan-Dombivali',
    'Vasai-Virar',
    'Varanasi',
    'Srinagar',
    'Aurangabad',
    'Dhanbad',
    'Amritsar',
    'Navi Mumbai',
    'Allahabad',
    'Ranchi',
    'Howrah',
    'Coimbatore',
    'Jabalpur',
    'Gwalior',
    'Vijayawada',
    'Jodhpur',
    'Madurai',
    'Raipur',
    'Kota',
    'Chandigarh',
    'Guwahati',
    'Mysore',
    'Other',
  ];

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _cityController.dispose();
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
            _emailController.clear();
            _dobController.clear();
            _cityController.clear();
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
    final trimmedEmail = email.trim();
    final trimmedDob = dob.trim();
    final trimmedCity = city.trim();

    if (trimmedName.isEmpty) {
      _toast('Please enter your full name', error: true);
      return;
    }

    if (trimmedName.length < 2) {
      _toast('Name must be at least 2 characters', error: true);
      return;
    }

    if (trimmedEmail.isEmpty) {
      _toast('Please enter your email address', error: true);
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      _toast('Please enter a valid email address', error: true);
      return;
    }

    if (trimmedDob.isEmpty) {
      _toast('Please select your date of birth', error: true);
      return;
    }

    // Validate age (must be 25+)
    final dobDate = DateTime.parse(trimmedDob);
    final age = DateTime.now().difference(dobDate).inDays ~/ 365;

    if (age < 25) {
      _toast('You must be 25 years or older to use SipZy', error: true);
      return;
    }

    if (age > 120) {
      _toast('Please enter a valid date of birth', error: true);
      return;
    }

    if (!confirmedAge) {
      _toast('Please confirm you are 25 years of age or older', error: true);
      return;
    }

    if (!agreedToTerms) {
      _toast('Please agree to the Terms & Conditions', error: true);
      return;
    }

    if (!agreedToPrivacy) {
      _toast('Please agree to the Privacy Policy', error: true);
      return;
    }

    if (!confirmedAlcoholConsent) {
      _toast(
          'Please confirm you are legally permitted to view alcohol-related content',
          error: true);
      return;
    }

    setState(() => loading = true);

    try {
      print(
          '👤 Signing up: $trimmedName, email: $trimmedEmail, dob: $trimmedDob, phone: +91$phone');
      final result = await _authService.signUp(
        name: trimmedName,
        email: trimmedEmail,
        dob: trimmedDob,
        city: trimmedCity,
        phone: phone,
        enableLocation: enableLocation,
        enableNotifications: enableNotifications,
        enableSocialFeatures: enableSocialFeatures,
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

  Future<void> _selectDate() async {
    // Calculate date 25 years ago from today
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(now.year - 100, 1, 1);
    final lastDate = DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: const Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dob = picked.toIso8601String().split('T')[0];
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
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
                if (step != AuthStep.signup) _termsText(),
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
          'Create Your Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Complete your profile to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 24),

        // Profile Photo (Optional) - Circular placeholder
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3A3A3A),
                  border: Border.all(
                    color: const Color(0xFF4A4A4A),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white38,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Profile Photo (Optional)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Personal Information Section
        Row(
          children: const [
            Icon(Icons.person, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'Personal Information',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Full Name
        _buildLabel('Full Name', required: true),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (v) => name = v,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Aumita'),
        ),

        const SizedBox(height: 16),

        // Phone Number (Read-only)
        _buildLabel('Phone Number', required: true),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: phone),
          enabled: false,
          style: const TextStyle(color: Colors.white54),
          decoration: _inputDecoration('9988988988'),
        ),

        const SizedBox(height: 16),

        // Email Address
        _buildLabel('Email Address', required: true),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          onChanged: (v) => email = v,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('test@gmail.com')
              .copyWith(helperText: 'Used for account recovery & updates'),
        ),

        const SizedBox(height: 16),

        // City Dropdown
        _buildLabel('City', required: false),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: city.isEmpty ? null : city,
          items: _indianCities.map((cityName) {
            return DropdownMenuItem(
              value: cityName,
              child: Text(cityName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              city = value ?? '';
            });
          },
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF3A3A3A),
          decoration: _inputDecoration('Select your city'),
        ),

        const SizedBox(height: 20),

        // Age Verification Section
        Row(
          children: const [
            Icon(Icons.verified_user, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'Age Verification (Required)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date of Birth
        _buildLabel('Date of birth', required: true),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: _dobController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('dd-mm-yyyy')
                  .copyWith(suffixIcon: const Icon(Icons.calendar_today)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Age Confirmation Checkbox
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: confirmedAge,
                  onChanged: (v) => setState(() => confirmedAge = v ?? false),
                  activeColor: const Color(0xFFF5B642),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: 'I confirm that I am '),
                      TextSpan(
                        text: '25 years of age or older',
                        style: TextStyle(color: Color(0xFFF5B642)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Location Section
        Row(
          children: const [
            Icon(Icons.location_on, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'Location (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enable Location
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'For nearby restaurant discovery',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enableLocation,
                onChanged: (v) => setState(() => enableLocation = v),
                activeColor: const Color(0xFFF5B642),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Legal Consents Section
        Row(
          children: const [
            Icon(Icons.gavel, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'LEGAL CONSENTS (REQUIRED)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Combined Legal Consent
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: agreedToTerms &&
                      agreedToPrivacy &&
                      confirmedAlcoholConsent,
                  onChanged: (v) => setState(() {
                    agreedToTerms = v ?? false;
                    agreedToPrivacy = v ?? false;
                    confirmedAlcoholConsent = v ?? false;
                  }),
                  activeColor: const Color(0xFFF5B642),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Open T&C
                          },
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: Color(0xFFF5B642),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ', '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Open Privacy Policy
                          },
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFFF5B642),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ' and confirm I am legally permitted to view alcohol-related content.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Notifications Section
        Row(
          children: const [
            Icon(Icons.notifications, color: Color(0xFFF5B642), size: 18),
            SizedBox(width: 8),
            Text(
              'Notifications (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Enable Notifications
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Push Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get updates about new releases & events',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enableNotifications,
                onChanged: (v) => setState(() => enableNotifications = v),
                activeColor: const Color(0xFFF5B642),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Enable Social Features
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Social Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Connect with friends & share reviews',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enableSocialFeatures,
                onChanged: (v) => setState(() => enableSocialFeatures = v),
                activeColor: const Color(0xFFF5B642),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Create Account Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : signup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5B642),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              loading ? 'Creating Account…' : 'Create Account',
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF3A3A3A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
      ],
    );
  }
}
