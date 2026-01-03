import 'package:flutter/material.dart';

class SipzyProgress extends StatelessWidget {
  final double value; // 0 → 100
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final Duration animationDuration;

  const SipzyProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor = const Color(0x33FFC107), // amber 20%
    this.progressColor = const Color(0xFFFFC107), // amber
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0, 100);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        width: double.infinity,
        color: backgroundColor,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clampedValue / 100),
          duration: animationDuration,
          builder: (context, progress, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
