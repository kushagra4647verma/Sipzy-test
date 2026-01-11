import 'package:flutter/material.dart';
import 'dart:ui';

/// App Theme Configuration
/// Matches React Native design system exactly
class AppTheme {
  // ==================== COLORS ====================

  static const primary = Color(0xFFF59E0B); // Amber-500
  static const primaryLight = Color(0xFFFCD34D); // Amber-300
  static const secondary = Color(0xFFA855F7); // Purple-500
  static const secondaryLight = Color(0xFFC084FC); // Purple-400

  static const background = Color(0xFF0A0A0A);
  static const foreground = Color(0xFAFAFAFA);
  static const card = Color(0xFF141414);
  static const border = Color(0x33FFFFFF); // 20% white

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99FFFFFF); // 60% white
  static const textTertiary = Color(0x66FFFFFF); // 40% white

  // Glass effects
  static const glassLight = Color(0x0DFFFFFF); // 5% white
  static const glassStrong = Color(0x1AFFFFFF); // 10% white

  // ==================== SPACING ====================

  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing48 = 48.0;
  static const spacing64 = 64.0;

  // ==================== BORDER RADIUS ====================

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;
  static const radius2xl = 28.0;
  static const radiusFull = 9999.0;

  // ==================== THEME DATA ====================

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: card,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 56,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 44,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),

      // Input theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),

      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: spacing16,
      ),
    );
  }

  // ==================== CUSTOM WIDGETS ====================

  /// Glass Container Widget (Light variant)
  static Widget glassContainer({
    required Widget child,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    bool strong = false,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(spacing16),
      decoration: BoxDecoration(
        color: strong ? glassStrong : glassLight,
        borderRadius: borderRadius ?? BorderRadius.circular(radiusLg),
        border: Border.all(
          color: strong ? border.withOpacity(0.2) : border.withOpacity(0.1),
        ),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: strong ? 20 : 12,
          sigmaY: strong ? 20 : 12,
        ),
        child: child,
      ),
    );
  }

  /// Gradient Button Widget (Amber variant)
  static Widget gradientButtonAmber({
    required Widget child,
    required VoidCallback onPressed,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(radiusMd),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(radiusMd),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: spacing24,
                  vertical: spacing12,
                ),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Gradient Button Widget (Purple variant)
  static Widget gradientButtonPurple({
    required Widget child,
    required VoidCallback onPressed,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [secondary, secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(radiusMd),
        boxShadow: [
          BoxShadow(
            color: secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(radiusMd),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: spacing24,
                  vertical: spacing12,
                ),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Gradient Text Widget (Amber)
  static Widget gradientTextAmber(String text, {TextStyle? style}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [primary, primaryLight],
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ??
                const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                ))
            .copyWith(color: Colors.white),
      ),
    );
  }

  /// Gradient Text Widget (Purple)
  static Widget gradientTextPurple(String text, {TextStyle? style}) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [secondary, secondaryLight],
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ??
                const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                ))
            .copyWith(color: Colors.white),
      ),
    );
  }
}

// Import for BackdropFilter
