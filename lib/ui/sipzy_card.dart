import 'package:flutter/material.dart';

/// ===============================
/// ROOT CARD
/// ===============================
class SipzyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const SipzyCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16), // rounded-xl
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}

/// ===============================
/// CARD HEADER
/// ===============================
class SipzyCardHeader extends StatelessWidget {
  final Widget child;

  const SipzyCardHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }
}

/// ===============================
/// CARD TITLE
/// ===============================
class SipzyCardTitle extends StatelessWidget {
  final String text;

  const SipzyCardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }
}

/// ===============================
/// CARD DESCRIPTION
/// ===============================
class SipzyCardDescription extends StatelessWidget {
  final String text;

  const SipzyCardDescription(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.white60),
    );
  }
}

/// ===============================
/// CARD CONTENT
/// ===============================
class SipzyCardContent extends StatelessWidget {
  final Widget child;

  const SipzyCardContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: child,
    );
  }
}

/// ===============================
/// CARD FOOTER
/// ===============================
class SipzyCardFooter extends StatelessWidget {
  final Widget child;

  const SipzyCardFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [child],
      ),
    );
  }
}
