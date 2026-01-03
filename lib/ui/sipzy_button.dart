import 'package:flutter/material.dart';

enum ButtonVariant { primary, destructive, outline, secondary, ghost, link }

enum ButtonSize { sm, md, lg, icon }

class SipzyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;

  const SipzyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = _style(context);

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: style,
      child: child,
    );
  }

  // ---------------- STYLES ----------------

  ButtonStyle _style(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ElevatedButton.styleFrom(
      elevation: _elevation,
      backgroundColor: _backgroundColor(colors),
      foregroundColor: _foregroundColor(colors),
      padding: _padding,
      minimumSize: _minSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: _border(colors),
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(
        Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  // ---------------- VARIANT ----------------

  Color _backgroundColor(ColorScheme colors) {
    if (disabled) return Colors.white12;

    switch (variant) {
      case ButtonVariant.primary:
        return colors.primary;
      case ButtonVariant.destructive:
        return Colors.red.shade600;
      case ButtonVariant.secondary:
        return Colors.white12;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return Colors.transparent;
    }
  }

  Color _foregroundColor(ColorScheme colors) {
    if (disabled) return Colors.white38;

    switch (variant) {
      case ButtonVariant.primary:
        return Colors.black;
      case ButtonVariant.destructive:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return Colors.white;
      case ButtonVariant.link:
        return colors.primary;
    }
  }

  BorderSide _border(ColorScheme colors) {
    if (variant == ButtonVariant.outline) {
      return const BorderSide(color: Colors.white24);
    }
    return BorderSide.none;
  }

  double get _elevation {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.destructive:
      case ButtonVariant.secondary:
        return 2;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
      case ButtonVariant.link:
        return 0;
    }
  }

  // ---------------- SIZE ----------------

  EdgeInsets get _padding {
    switch (size) {
      case ButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 12);
      case ButtonSize.icon:
        return const EdgeInsets.all(10);
      case ButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }
  }

  Size get _minSize {
    switch (size) {
      case ButtonSize.sm:
        return const Size(0, 32);
      case ButtonSize.lg:
        return const Size(0, 44);
      case ButtonSize.icon:
        return const Size(40, 40);
      case ButtonSize.md:
        return const Size(0, 36);
    }
  }
}
