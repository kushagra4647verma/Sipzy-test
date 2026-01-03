import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExpertBottomNav extends StatelessWidget {
  final String active;

  const ExpertBottomNav({super.key, required this.active});

  void _navigate(BuildContext context, String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ExpertNavItem(
        id: 'home',
        label: 'SipZy',
        icon: Icons.local_bar,
        route: '/expert',
      ),
      _ExpertNavItem(
        id: 'tasks',
        label: 'Expert Tasks',
        icon: Icons.assignment,
        route: '/expert/tasks',
      ),
      _ExpertNavItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person,
        route: '/expert/profile',
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.map((tab) {
              final isActive = tab.id == active;

              return GestureDetector(
                onTap: () => _navigate(context, tab.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF7C3AED), // purple-600
                              Color(0xFFA855F7), // purple-400
                            ],
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 22,
                        color: isActive ? Colors.white : Colors.white60,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ExpertNavItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;

  _ExpertNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });
}
