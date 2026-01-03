import 'package:flutter/material.dart';
import 'sipzy_toast.dart';

class SipzyToastWidget extends StatelessWidget {
  final String title;
  final String? description;
  final ToastType type;
  final VoidCallback onClose;

  const SipzyToastWidget({
    super.key,
    required this.title,
    this.description,
    required this.type,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isError = type == ToastType.destructive;

    return Positioned(
      top: 40,
      right: 16,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedSlide(
          offset: Offset.zero,
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 36, 14),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade600 : const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isError ? Colors.redAccent : Colors.white12,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 12),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.white70,
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
