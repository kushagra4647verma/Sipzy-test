import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../shared/navigation/expert_bottom_nav.dart';
import '../../config/env_config.dart';

class ExpertTasksPage extends StatefulWidget {
  final Map<String, dynamic> expert;

  const ExpertTasksPage({super.key, required this.expert});

  @override
  State<ExpertTasksPage> createState() => _ExpertTasksPageState();
}

class _ExpertTasksPageState extends State<ExpertTasksPage> {
  static const api = EnvConfig.apiBaseUrl;

  List assignedRestaurants = [];
  List completedTasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() => loading = true);

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$api/expert/${widget.expert['id']}/assigned-restaurants'),
        ),
        http.get(
          Uri.parse('$api/expert/${widget.expert['id']}/completed-tasks'),
        ),
      ]);

      if (mounted) {
        setState(() {
          assignedRestaurants = jsonDecode(responses[0].body);
          completedTasks = jsonDecode(responses[1].body);
        });
      }
    } catch (_) {
      _toast('Failed to load tasks', error: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? Colors.red : AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchTasks,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _header(),
                    const SizedBox(height: 24),
                    _statsCards(),
                    const SizedBox(height: 24),
                    if (assignedRestaurants.isNotEmpty) ...[
                      _sectionTitle('Pending Tasks'),
                      const SizedBox(height: 12),
                      ...assignedRestaurants.map((r) => _taskCard(r)),
                    ] else
                      _emptyState(),
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionTitle('Completed Today'),
                      const SizedBox(height: 12),
                      ...completedTasks.map((t) => _completedCard(t)),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const ExpertBottomNav(active: 'tasks'),
    );
  }

  // ---------------- Header ----------------

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.assignment, color: AppColors.secondary, size: 28),
            SizedBox(width: 8),
            Text(
              'Expert Tasks',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hello, ${widget.expert['name']}!',
          style: const TextStyle(color: Colors.white60),
        ),
      ],
    );
  }

  // ---------------- Stats Cards ----------------

  Widget _statsCards() {
    final pending = assignedRestaurants.length;
    final completed = completedTasks.length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.pending_actions,
            value: pending.toString(),
            label: 'Pending',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.check_circle,
            value: completed.toString(),
            label: 'Completed Today',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------- Section Title ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ---------------- Task Card ----------------

  Widget _taskCard(Map restaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  restaurant['image'] ?? '',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    color: AppColors.muted,
                    child: const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Rate',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant['name'] ?? 'Unknown Restaurant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      restaurant['area'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (restaurant['cuisine'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    (restaurant['cuisine'] as List).join(' • '),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to rating page
                          _toast('Rating feature coming soon');
                        },
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Start Rating'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // TODO: View restaurant details
                        _toast('View details coming soon');
                      },
                      icon: const Icon(Icons.info_outline),
                      color: Colors.white70,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Completed Card ----------------

  Widget _completedCard(Map task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['restaurant_name'] ?? 'Restaurant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task['beverages_rated'] ?? 0} beverages rated',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            task['time'] ?? '',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ---------------- Empty State ----------------

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending tasks at the moment.\nCheck back later for new assignments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: fetchTasks,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
