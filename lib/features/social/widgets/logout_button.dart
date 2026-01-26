import 'package:flutter/material.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Logout?'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        // clear auth & tokens here
                        Navigator.pop(context);
                      },
                      child: const Text('Logout')),
                ],
              ),
            );
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
