import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Modern Animated Splash Screen
/// Matches React Native design with pulsing animations
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Pulse animation for background blobs
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Scale animation for logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated background blobs
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Top-left amber blob
                    Positioned(
                      top: 100,
                      left: 50,
                      child: _GlowingBlob(
                        size: 250 + (_pulseController.value * 30),
                        color: AppTheme.primary,
                        opacity: 0.15 + (_pulseController.value * 0.05),
                      ),
                    ),
                    // Bottom-right purple blob
                    Positioned(
                      bottom: 100,
                      right: 50,
                      child: _GlowingBlob(
                        size: 250 + ((1 - _pulseController.value) * 30),
                        color: AppTheme.secondary,
                        opacity: 0.15 + ((1 - _pulseController.value) * 0.05),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Logo and text
          Center(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _scaleController,
                    builder: (context, child) {
                      final scale = 1.0 + (_scaleController.value * 0.1);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.3),
                                AppTheme.primary.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.local_bar_rounded,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Brand name with gradient
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTheme.gradientTextAmber(
                        'Sip',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      AppTheme.gradientTextPurple(
                        'Zy',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  const Text(
                    'Discover. Rate. Share.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.2,
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

/// Glowing blob widget for background animation
class _GlowingBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowingBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.5),
            blurRadius: 120,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
