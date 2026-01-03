import 'package:flutter/material.dart';

class SipzyDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool disabled;

  SipzyDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.disabled = false,
  });
}

class SipzyDropdownMenu<T> extends StatelessWidget {
  final Widget trigger;
  final List<SipzyDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final T? selectedValue;

  const SipzyDropdownMenu({
    super.key,
    required this.trigger,
    required this.items,
    required this.onSelected,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: '',
      offset: const Offset(0, 8),
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.white24),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<T>(
            value: item.value,
            enabled: !item.disabled,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: item.disabled ? Colors.white38 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (selectedValue == item.value)
                  const Icon(Icons.check, size: 16, color: Colors.amber),
              ],
            ),
          );
        }).toList();
      },
      child: trigger,
    );
  }
}
