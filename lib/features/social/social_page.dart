import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../services/camera_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../ui/toast/sipzy_toast.dart';
import 'widgets/profile_header.dart';
import 'tabs/ratings_tab.dart';
import 'tabs/diary_tab.dart';
import 'tabs/badges_tab.dart';
import 'tabs/saves_tab.dart';
import 'tabs/friends_tab.dart';

class SocialPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const SocialPage({super.key, required this.user, required this.onLogout});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _userService = UserService();
  final _cameraService = CameraService();

  late TabController _tabController;

  bool loading = true;
  bool hasError = false;

  Map<String, dynamic> stats = {
    'ratingsCount': 0,
    'friendsCount': 0,
    'badgesCount': 0,
  };

  List ratings = [];
  List diaryEntries = [];
  List badges = [];
  List bookmarks = [];
  List friends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAll() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final userId =
          _supabase.auth.currentUser?.id ?? widget.user['id']?.toString() ?? '';

      final results = await Future.wait([
        _userService.getUserRatings(userId),
        _userService.getDiary(),
        _userService.getBookmarks(),
        _userService.getFriends(),
        _userService.getBadges(),
        _userService.getUserStats(userId),
      ]);

      if (mounted) {
        setState(() {
          ratings = (results[0] as List?) ?? [];
          diaryEntries = (results[1] as List?) ?? [];
          bookmarks = (results[2] as List?) ?? [];
          friends = (results[3] as List?) ?? [];
          badges = (results[4] as List?) ?? [];

          final apiStats = results[5] as Map<String, dynamic>;
          stats = {
            'ratingsCount': apiStats['ratingsCount'] ?? ratings.length,
            'friendsCount': apiStats['friendsCount'] ?? friends.length,
            'badgesCount': apiStats['badgesCount'] ??
                badges.where((b) => b['earned'] == true).length,
            'bookmarksCount': apiStats['bookmarksCount'] ?? bookmarks.length,
            'diaryEntriesCount':
                apiStats['diaryEntriesCount'] ?? diaryEntries.length,
          };

          hasError = false;
        });
      }
    } catch (e) {
      print('❌ Social fetchAll error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _showToast('Failed to load profile data', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final success = await _userService.updateProfile(updates);

      if (success) {
        _showToast('Profile updated');
        final updatedProfile = await _userService.getMyProfile();
        if (updatedProfile != null && mounted) {
          setState(() {
            widget.user.addAll(updatedProfile);
          });
        }
      } else {
        _showToast('Failed to update profile', isError: true);
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      _showToast('Error updating profile', isError: true);
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    SipzyToast.show(
      context,
      title: msg,
      type: isError ? ToastType.destructive : ToastType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(child: _buildLoadingSkeleton()),
        bottomNavigationBar: const BottomNav(active: 'social'),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(child: _buildErrorState()),
        bottomNavigationBar: const BottomNav(active: 'social'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            ProfileHeader(
              user: widget.user,
              stats: stats,
              onEditProfile: updateProfile,
              onLogout: logout,
            ),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RatingsTab(ratings: ratings, onRefresh: fetchAll),
                  DiaryTab(
                    diaryEntries: diaryEntries,
                    cameraService: _cameraService,
                    userService: _userService,
                    onRefresh: fetchAll,
                    showToast: _showToast,
                  ),
                  BadgesTab(
                    badges: badges,
                    stats: stats,
                    bookmarks: bookmarks,
                    onRefresh: fetchAll,
                  ),
                  SavesTab(
                    bookmarks: bookmarks,
                    userService: _userService,
                    onRefresh: fetchAll,
                    showToast: _showToast,
                  ),
                  FriendsTab(
                    friends: friends,
                    userService: _userService,
                    onRefresh: fetchAll,
                    showToast: _showToast,
                  ),
                ],
              ),
            ),
            _buildLogoutButton(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'social'),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          _buildTab('Ratings', 0),
          _buildTab('Diary', 1),
          _buildTab('Badges', 2),
          _buildTab('Saves', 3),
          _buildTab('Friends', 4),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFF5A623), Color(0xFFFFCC70)])
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout, size: 18, color: Colors.white),
          label: const Text('Logout',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7F1D1D),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text('Unable to load profile',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Check your connection and try again',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
