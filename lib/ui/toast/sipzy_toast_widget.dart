import 'package:flutter/material.dart';
import 'sipzy_toast.dart';

class SipzyToastWidget extends StatefulWidget {
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
  State<SipzyToastWidget> createState() => _SipzyToastWidgetState();
}

class _SipzyToastWidgetState extends State<SipzyToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.type == ToastType.destructive;

    // ✅ FIXED: Better color contrast for visibility
    final backgroundColor = isError
        ? const Color(0xFFDC2626) // Brighter red for errors
        : const Color(0xFF1F2937); // Slightly lighter dark gray

    final borderColor = isError
        ? const Color(0xFFEF4444) // Lighter red border
        : const Color(0xFF374151); // Visible gray border

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      left: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ✅ Icon for visual feedback
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFFF5B642).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? Colors.white : const Color(0xFFF5B642),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white, // ✅ Pure white for contrast
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.9), // ✅ High opacity
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white.withOpacity(0.8),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
