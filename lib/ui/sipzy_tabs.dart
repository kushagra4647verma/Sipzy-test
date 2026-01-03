import 'package:flutter/material.dart';

/// ===============================
/// ROOT TABS CONTROLLER
/// ===============================
class SipzyTabs extends StatefulWidget {
  final int initialIndex;
  final List<String> tabs;
  final List<Widget> children;

  const SipzyTabs({
    super.key,
    this.initialIndex = 0,
    required this.tabs,
    required this.children,
  });

  @override
  State<SipzyTabs> createState() => _SipzyTabsState();
}

class _SipzyTabsState extends State<SipzyTabs> {
  late int activeIndex;

  @override
  void initState() {
    super.initState();
    activeIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SipzyTabsList(
          tabs: widget.tabs,
          activeIndex: activeIndex,
          onChanged: (i) => setState(() => activeIndex = i),
        ),
        const SizedBox(height: 8),
        SipzyTabContent(child: widget.children[activeIndex]),
      ],
    );
  }
}

/// ===============================
/// TABS LIST
/// ===============================
class SipzyTabsList extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const SipzyTabsList({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (i) => Expanded(
            child: SipzyTabTrigger(
              text: tabs[i],
              isActive: i == activeIndex,
              onTap: () => onChanged(i),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// TAB TRIGGER
/// ===============================
class SipzyTabTrigger extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const SipzyTabTrigger({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6)]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// TAB CONTENT
/// ===============================
class SipzyTabContent extends StatelessWidget {
  final Widget child;

  const SipzyTabContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
