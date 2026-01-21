import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/env_config.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../shared/navigation/expert_bottom_nav.dart';

class ExpertDashboard extends StatefulWidget {
  final Map<String, dynamic> expert;

  const ExpertDashboard({super.key, required this.expert});

  @override
  State<ExpertDashboard> createState() => _ExpertDashboardState();
}

class _ExpertDashboardState extends State<ExpertDashboard> {
  static const api = EnvConfig.apiBaseUrl;

  List assignedRestaurants = [];
  Map<String, dynamic> recentlyRated = {'weekly_count': 0, 'restaurants': []};
  Map<String, dynamic> stats = {
    'total_ratings': 0,
    'avg_score_given': 0,
    'beverages_this_week': 0,
  };

  bool loading = true;
  bool showRecentModal = false;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    // setState(() => loading = true);

    // try {
    //   final responses = await Future.wait([
    //     http.get(
    //       Uri.parse('$api/expert/${widget.expert['id']}/assigned-restaurants'),
    //     ),
    //     http.get(
    //       Uri.parse('$api/expert/${widget.expert['id']}/recently-rated'),
    //     ),
    //     http.get(Uri.parse('$api/expert/${widget.expert['id']}/stats')),
    //   ]);

    //   setState(() {
    //     assignedRestaurants = jsonDecode(responses[0].body);
    //     recentlyRated = jsonDecode(responses[1].body);
    //     stats = jsonDecode(responses[2].body);
    //   });
    // } catch (_) {
    //   _toast('Failed to load dashboard data', error: true);
    // } finally {
    //   setState(() => loading = false);
    // }

    setState(() {
      assignedRestaurants = [
        {'id': 1, 'name': 'Toit Brewpub', 'area': 'Koramangala', 'image': ''},
      ];

      recentlyRated = {'weekly_count': 12, 'restaurants': []};

      stats = {
        'total_ratings': 45,
        'avg_score_given': 4.3,
        'beverages_this_week': 12,
      };

      loading = false;
    });
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _header(),
            _statsSection(),
            _assignedRestaurants(),
            _recentlyRatedTile(),
          ],
        ),
      ),
      bottomNavigationBar: const ExpertBottomNav(active: 'home'),
    );
  }

  // ---------------- Header ----------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondary,
                backgroundImage: widget.expert['avatar'] != null
                    ? NetworkImage(widget.expert['avatar'])
                    : null,
                child: widget.expert['avatar'] == null
                    ? const Icon(Icons.verified_user, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hello,', style: TextStyle(color: Colors.white60)),
                  Text(
                    '${widget.expert['name']}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
              color: AppColors.secondary.withValues(alpha: 0.15),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.secondary, size: 14),
                SizedBox(width: 6),
                Text(
                  'Verified Expert',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Stats ----------------

  Widget _statsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expert Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                icon: Icons.star,
                value: stats['total_ratings'].toString(),
                label: 'Total Ratings',
                color: AppColors.primary,
              ),
              _statCard(
                icon: Icons.trending_up,
                value: stats['avg_score_given'].toString(),
                label: 'Avg Score',
                color: AppColors.secondary,
              ),
              _statCard(
                icon: Icons.local_bar,
                value: stats['beverages_this_week'].toString(),
                label: 'This Week',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Assigned Restaurants ----------------

  Widget _assignedRestaurants() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Exploration",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (assignedRestaurants.isNotEmpty)
                Text(
                  '${assignedRestaurants.length} pending',
                  style: const TextStyle(color: AppColors.secondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (assignedRestaurants.isEmpty)
            _emptyAssigned()
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: assignedRestaurants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (_, i) => _assignedCard(assignedRestaurants[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _assignedCard(Map restaurant) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/expert/restaurant/${restaurant['id']}',
      ),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    restaurant['image'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        restaurant['area'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: const Text('Start Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAssigned() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified, color: AppColors.secondary, size: 40),
          SizedBox(height: 8),
          Text(
            'No restaurants assigned for today',
            style: TextStyle(color: Colors.white60),
          ),
          SizedBox(height: 4),
          Text(
            'Check back tomorrow!',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------- Recently Rated ----------------

  Widget _recentlyRatedTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => setState(() => showRecentModal = true),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.star, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recently Rated',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${recentlyRated['weekly_count']} beverages this week',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }
}
