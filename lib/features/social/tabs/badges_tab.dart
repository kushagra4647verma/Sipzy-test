import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BadgesTab extends StatefulWidget {
  final List badges;
  final Map<String, dynamic> stats;
  final List bookmarks;
  final VoidCallback onRefresh;

  const BadgesTab({
    super.key,
    required this.badges,
    required this.stats,
    required this.bookmarks,
    required this.onRefresh,
  });

  @override
  State<BadgesTab> createState() => _BadgesTabState();
}

class _BadgesTabState extends State<BadgesTab> {
  String badgeFilter = 'all';

  final Map<String, List<Map<String, dynamic>>> tierBadges = {
    'Tier 1': [
      {
        'name': 'Sip Rookie',
        'icon': '🪣',
        'target': 5,
        'type': 'ratings',
        'description': 'Rate your first 5 drinks'
      },
      {
        'name': 'Introvert',
        'icon': '👤',
        'target': 5,
        'type': 'friends',
        'description': 'Add 5 friends'
      },
      {
        'name': 'Hopper',
        'icon': '🗺️',
        'target': 5,
        'type': 'bookmarks',
        'description': 'Bookmark 5 places'
      },
    ],
    'Tier 2': [
      {
        'name': 'Alchemist',
        'icon': '⚗️',
        'target': 50,
        'type': 'ratings',
        'description': 'Rate 50 drinks'
      },
      {
        'name': 'Social Butterfly',
        'icon': '🦋',
        'target': 50,
        'type': 'friends',
        'description': 'Build a network of 50 friends'
      },
      {
        'name': 'SipZy Crawler',
        'icon': '🕷️',
        'target': 50,
        'type': 'bookmarks',
        'description': 'Bookmark 50 venues'
      },
    ],
    'Tier 3': [
      {
        'name': 'Connoisseur',
        'icon': '👑',
        'target': 100,
        'type': 'ratings',
        'description': 'Rate 100 drinks like a pro'
      },
      {
        'name': 'Tribe Star',
        'icon': '⭐',
        'target': 100,
        'type': 'friends',
        'description': 'Create a tribe of 100 friends'
      },
      {
        'name': 'SipZy NoMad',
        'icon': '🌍',
        'target': 100,
        'type': 'bookmarks',
        'description': 'Bookmark 100 places across cities'
      },
    ],
  };

  int getProgress(String type) {
    switch (type) {
      case 'ratings':
        return widget.stats['ratingsCount'] ?? 0;
      case 'friends':
        return widget.stats['friendsCount'] ?? 0;
      case 'bookmarks':
        return widget.bookmarks.length;
      default:
        return 0;
    }
  }

  List<Map<String, dynamic>> _generateBadges() {
    final List<Map<String, dynamic>> allBadges = [];

    tierBadges.forEach((tier, badges) {
      for (final badge in badges) {
        final progress = getProgress(badge['type']);
        final target = badge['target'] as int;
        final earned = progress >= target;

        allBadges.add({
          'tier': tier,
          'name': badge['name'],
          'icon': badge['icon'],
          'description': badge['description'],
          'type': badge['type'],
          'target': target,
          'progress': progress,
          'earned': earned,
        });
      }
    });

    return allBadges;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildBadgesList()),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Earned', 'earned'),
          const SizedBox(width: 8),
          _buildFilterChip('In Progress', 'in_progress'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = badgeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => badgeFilter = value);
          // Refresh data when filter changes
          widget.onRefresh();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFFFCC70)])
                : null,
            color: isSelected ? null : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesList() {
    final allBadges = _generateBadges();
    List<Map<String, dynamic>> filteredBadges = allBadges;

    if (badgeFilter == 'earned') {
      filteredBadges = allBadges.where((b) => b['earned'] == true).toList();
    } else if (badgeFilter == 'in_progress') {
      filteredBadges = allBadges.where((b) => b['earned'] == false).toList();
    }

    if (filteredBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              badgeFilter == 'earned'
                  ? 'No badges earned yet'
                  : 'All badges unlocked!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              badgeFilter == 'earned'
                  ? 'Keep exploring to earn badges'
                  : 'Amazing work!',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildTierSection(
            'Tier 1', 'Newbie', const Color(0xFF8B7355), filteredBadges),
        const SizedBox(height: 16),
        _buildTierSection(
            'Tier 2', 'SipZeR', const Color(0xFF5B21B6), filteredBadges),
        const SizedBox(height: 16),
        _buildTierSection(
            'Tier 3', 'Alpha Z', const Color(0xFF059669), filteredBadges),
      ],
    );
  }

  Widget _buildTierSection(String tier, String subtitle, Color color,
      List<Map<String, dynamic>> allBadges) {
    final tierBadges = allBadges.where((b) => b['tier'] == tier).toList();

    if (tierBadges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_getTierIcon(tier), color: color, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Badges
        ...tierBadges.map((badge) => _buildBadgeCard(badge, color)),
      ],
    );
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'Tier 1':
        return Icons.emoji_events_outlined;
      case 'Tier 2':
        return Icons.auto_awesome;
      case 'Tier 3':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  Widget _buildBadgeCard(Map badge, Color tierColor) {
    final progress = badge['progress'] as int;
    final target = badge['target'] as int;
    final earned = badge['earned'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  earned ? tierColor.withOpacity(0.2) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                badge['icon'],
                style: TextStyle(
                  fontSize: 28,
                  color: earned ? null : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge['name'],
                  style: TextStyle(
                    color: earned ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progress/$target completed',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
