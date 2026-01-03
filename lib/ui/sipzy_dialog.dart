import 'dart:ui';
import 'package:flutter/material.dart';

/// ===============================
/// ROOT DIALOG
/// ===============================
class SipzyDialog extends StatelessWidget {
  final Widget child;

  const SipzyDialog({super.key, required this.child});

  static Future<void> show(
    BuildContext context, {
    required Widget child,
    bool dismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => SipzyDialog(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: child,
      ),
    );
  }
}

/// ===============================
/// DIALOG CONTENT
/// ===============================
class SipzyDialogContent extends StatelessWidget {
  final Widget child;

  const SipzyDialogContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(24), child: child),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.white70,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// DIALOG HEADER
/// ===============================
class SipzyDialogHeader extends StatelessWidget {
  final Widget child;

  const SipzyDialogHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [child],
    );
  }
}

/// ===============================
/// DIALOG TITLE
/// ===============================
class SipzyDialogTitle extends StatelessWidget {
  final String text;

  const SipzyDialogTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// ===============================
/// DIALOG DESCRIPTION
/// ===============================
class SipzyDialogDescription extends StatelessWidget {
  final String text;

  const SipzyDialogDescription(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
      ),
    );
  }
}

/// ===============================
/// DIALOG FOOTER
/// ===============================
class SipzyDialogFooter extends StatelessWidget {
  final List<Widget> actions;

  const SipzyDialogFooter({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .map(
              (a) => Padding(padding: const EdgeInsets.only(left: 8), child: a),
            )
            .toList(),
      ),
    );
  }
}
