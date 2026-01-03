import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../shared/navigation/expert_bottom_nav.dart';

class ExpertProfilePage extends StatefulWidget {
  final Map<String, dynamic> expert;
  final Function(Map<String, dynamic>?) onExpertChanged;

  const ExpertProfilePage({
    super.key,
    required this.expert,
    required this.onExpertChanged,
  });

  @override
  State<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends State<ExpertProfilePage> {
  static const API = String.fromEnvironment('API_URL');

  Map<String, dynamic> stats = {
    'total_ratings': 0,
    'avg_score_given': 0,
    'beverages_this_week': 0,
  };

  bool showEditModal = false;
  bool loading = false;

  late TextEditingController nameCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController tagsCtrl;

  @override
  void initState() {
    super.initState();
    fetchStats();

    nameCtrl = TextEditingController(text: widget.expert['name']);
    bioCtrl = TextEditingController(text: widget.expert['bio'] ?? '');
    tagsCtrl = TextEditingController(
      text: (widget.expert['expertise_tags'] as List?)?.join(', ') ?? '',
    );
  }

  Future<void> fetchStats() async {
    try {
      final res = await http.get(
        Uri.parse('$API/expert/${widget.expert['id']}/stats'),
      );
      if (res.statusCode == 200) {
        setState(() => stats = jsonDecode(res.body));
      }
    } catch (_) {}
  }

  void logout() {
    widget.onExpertChanged(null);
    Navigator.pushReplacementNamed(context, '/expert/auth');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  Future<void> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      final res = await http.put(
        Uri.parse('$API/expert/${widget.expert['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameCtrl.text.trim(),
          'bio': bioCtrl.text.trim(),
          'expertise_tags': tagsCtrl.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        }),
      );

      final data = jsonDecode(res.body);
      widget.onExpertChanged(data['expert']);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [_profileHeader(), _statsSection(), _actions()],
        ),
      ),
      bottomNavigationBar: const ExpertBottomNav(active: 'profile'),
    );
  }

  // ---------------- Profile Header ----------------

  Widget _profileHeader() {
    final tags = widget.expert['expertise_tags'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.secondary,
            backgroundImage: widget.expert['avatar'] != null
                ? NetworkImage(widget.expert['avatar'])
                : null,
            child: widget.expert['avatar'] == null
                ? const Icon(Icons.verified_user, color: Colors.white, size: 40)
                : null,
          ),
          const SizedBox(height: 12),

          Text(
            widget.expert['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          _verifiedBadge(),

          if ((widget.expert['bio'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                widget.expert['bio'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: tags.map<Widget>((t) => _tagChip(t)).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            '${stats['total_ratings']} Total Ratings',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, color: AppColors.secondary, size: 14),
          SizedBox(width: 6),
          Text(
            'Verified Expert',
            style: TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tag, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            tag,
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------- Stats ----------------

  Widget _statsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox(
                stats['total_ratings'],
                'Beverages Rated',
                AppColors.primary,
              ),
              _statBox(
                stats['avg_score_given'],
                'Avg Score Given',
                AppColors.secondary,
              ),
              _statBox(stats['beverages_this_week'], 'This Week', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(dynamic value, String label, Color color) {
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
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Actions ----------------

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: () => _openEditModal(),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit Profile'),
            style: _outlineStyle(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            style: _outlineStyle(border: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlineStyle({Color border = Colors.white24}) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      side: BorderSide(color: border),
    );
  }

  // ---------------- Edit Modal ----------------

  void _openEditModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _input('Name', nameCtrl),
              const SizedBox(height: 12),
              _input('Bio', bioCtrl, maxLines: 4),
              const SizedBox(height: 12),
              _input('Expertise Tags (comma separated)', tagsCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: loading ? null : saveProfile,
            child: Text(loading ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
