import 'package:flutter/material.dart';
import 'sipzy_toast_widget.dart';

enum ToastType { normal, destructive }

class SipzyToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String title,
    String? description,
    ToastType type = ToastType.normal,
    Duration duration = const Duration(seconds: 3),
  }) {
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (_) => SipzyToastWidget(
        title: title,
        description: description,
        type: type,
        onClose: hide,
      ),
    );

    Overlay.of(context).insert(_entry!);

    Future.delayed(duration, hide);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// Helpers (matches `sonner`)
  static void success(BuildContext c, String msg) => show(c, title: msg);

  static void error(BuildContext c, String msg) =>
      show(c, title: msg, type: ToastType.destructive);
}
