import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> stats;
  final Function(Map<String, dynamic>) onEditProfile;
  final VoidCallback onLogout;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.stats,
    required this.onEditProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      color: AppTheme.background,
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          _buildUserInfo(context),
          const SizedBox(height: 8),
          _buildEditButton(context),
          const SizedBox(height: 20),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.background,
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.primary,
              child: Text(
                user['name']?[0]?.toUpperCase() ?? 'T',
                style: const TextStyle(
                    fontSize: 32,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.background, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      children: [
        Text(
          user['name'] ?? 'Test',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${(user['name'] ?? 'test').toLowerCase().replaceAll(' ', '')}',
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: 140,
      child: OutlinedButton.icon(
        onPressed: () => _showEditProfileDialog(context),
        icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
        label: const Text('Edit Profile',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            iconColor: AppTheme.primary,
            value: stats['ratingsCount'] ?? 0,
            label: 'Ratings',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            iconColor: AppTheme.secondary,
            value: stats['friendsCount'] ?? 0,
            label: 'Friends',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            iconColor: const Color(0xFFFFB800),
            value: stats['badgesCount'] ?? 0,
            label: 'Badges',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required int value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onEditProfile({
                'name': nameCtrl.text,
                'email': emailCtrl.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
