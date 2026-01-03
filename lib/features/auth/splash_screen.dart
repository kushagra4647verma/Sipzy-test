import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ---------- Animated background blobs ----------
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Stack(
                children: [
                  _GlowBlob(
                    controller: _pulseController,
                    color: AppColors.primary,
                    alignment: Alignment.topLeft,
                  ),
                  _GlowBlob(
                    controller: _pulseController,
                    color: AppColors.secondary,
                    alignment: Alignment.bottomRight,
                    delay: true,
                  ),
                ],
              ),
            ),
          ),

          // ---------- Logo + text ----------
          Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // glowing logo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFB000), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.local_drink_rounded, // GlassWater equivalent
                        size: 96,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // SipZy text
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sip',
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Color(0xFFFFB000), Color(0xFFFFD166)],
                              ).createShader(Rect.fromLTWH(0, 0, 100, 0)),
                          ),
                        ),
                        TextSpan(
                          text: 'Zy',
                          style: TextStyle(
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                              ).createShader(Rect.fromLTWH(0, 0, 100, 0)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Discover. Rate. Share.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Glow blob widget ----------------

class _GlowBlob extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final Alignment alignment;
  final bool delay;

  const _GlowBlob({
    required this.controller,
    required this.color,
    required this.alignment,
    this.delay = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final value = delay ? (1 - controller.value) : controller.value;

          return Container(
            width: 260,
            height: 260,
            margin: const EdgeInsets.all(64),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.4 * value),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6 * value),
                  blurRadius: 120,
                  spreadRadius: 40,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
