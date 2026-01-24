import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../services/camera_service.dart';
import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../ui/toast/sipzy_toast.dart';

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

  // User stats
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

  String badgeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // ✅ FIX: Listen to tab changes to rebuild FAB
    _tabController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to show/hide FAB
      }
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

      print('🔄 Fetching all data for user: $userId');

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

          // ✅ DEBUG: Log diary entries
          print('📖 Diary entries loaded: ${diaryEntries.length}');
          if (diaryEntries.isNotEmpty) {
            print('📖 First entry: ${diaryEntries[0]}');
          }

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

  // ============ DIARY CRUD OPERATIONS ============

  Future<void> addDiaryEntry({
    required String bevName,
    required String restaurant,
    required int rating,
    String? notes,
    String? image,
    bool sharedToFeed = false,
  }) async {
    if (bevName.isEmpty || rating < 1 || rating > 5) {
      _showToast('Please enter drink name and rating', isError: true);
      return;
    }

    try {
      print('📝 Adding diary entry: $bevName');

      final success = await _userService.addDiaryEntry({
        'bevName': bevName,
        'restaurant': restaurant,
        'rating': rating,
        'notes': notes ?? '',
        'image': image ?? '',
        'sharedToFeed': sharedToFeed,
      });

      if (success) {
        _showToast('Diary entry added');
        await fetchAll(); // Refresh to show new entry
      } else {
        _showToast('Failed to add diary entry', isError: true);
      }
    } catch (e) {
      print('❌ Add diary error: $e');
      _showToast('Error adding diary', isError: true);
    }
  }

  Future<void> updateDiaryEntry(
      String entryId, Map<String, dynamic> updates) async {
    try {
      final success = await _userService.updateDiaryEntry(entryId, updates);

      if (success) {
        _showToast('Diary updated');
        fetchAll();
      } else {
        _showToast('Failed to update diary', isError: true);
      }
    } catch (e) {
      print('❌ Update diary error: $e');
      _showToast('Error updating diary', isError: true);
    }
  }

  Future<void> deleteDiaryEntry(String entryId) async {
    try {
      print('🗑️ Deleting diary entry: $entryId');

      final success = await _userService.deleteDiaryEntry(entryId);

      if (success) {
        _showToast('Diary entry deleted');
        await fetchAll();
      } else {
        _showToast('Failed to delete diary', isError: true);
      }
    } catch (e) {
      print('❌ Delete diary error: $e');
      _showToast('Error deleting diary', isError: true);
    }
  }

  // ============ BOOKMARK OPERATIONS ============

  Future<void> removeBookmark(String restaurantId) async {
    try {
      final success = await _userService.removeBookmark(restaurantId);

      if (success) {
        _showToast('Bookmark removed');
        fetchAll();
      } else {
        _showToast('Failed to remove bookmark', isError: true);
      }
    } catch (e) {
      print('❌ Remove bookmark error: $e');
      _showToast('Error removing bookmark', isError: true);
    }
  }

  // ============ FRIEND OPERATIONS ============

  Future<void> addFriendByPhone(String phone) async {
    try {
      final result = await _userService.addFriendByPhone(phone);

      if (result != null && result['success'] == true) {
        _showToast('Friend added');
        fetchAll();
      } else {
        _showToast(result?['message'] ?? 'Failed to add friend', isError: true);
      }
    } catch (e) {
      print('❌ Add friend error: $e');
      _showToast('Error adding friend', isError: true);
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final success = await _userService.removeFriend(friendId);

      if (success) {
        _showToast('Friend removed');
        fetchAll();
      } else {
        _showToast('Failed to remove friend', isError: true);
      }
    } catch (e) {
      print('❌ Remove friend error: $e');
      _showToast('Error removing friend', isError: true);
    }
  }

  // ============ BADGE OPERATIONS ============

  Future<void> claimBadge(int badgeId) async {
    try {
      final success = await _userService.claimBadge(badgeId.toString());

      if (success) {
        _showToast('Badge unlocked! 🎉');
        fetchAll();
      } else {
        _showToast('Failed to claim badge', isError: true);
      }
    } catch (e) {
      print('❌ Claim badge error: $e');
      _showToast('Error claiming badge', isError: true);
    }
  }

  // ============ USER PROFILE OPERATIONS ============
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

  // ============ UTILITY METHODS ============

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
    print('🔨 Building SocialPage - Current tab: ${_tabController.index}');

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

    // ✅ FIX: Check current tab for FAB visibility
    final showFAB = _tabController.index == 1;
    print('🎯 FAB should show: $showFAB (tab index: ${_tabController.index})');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchAll,
          color: AppTheme.primary,
          backgroundColor: AppTheme.card,
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ratingsTab(),
                    _diaryTab(),
                    _badgesTab(),
                    _savesTab(),
                    _friendsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'social'),
      // ✅ FIX: Always show FAB when on diary tab
      floatingActionButton: showFAB
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              onPressed: () {
                print('➕ Add Diary button pressed');
                _showAddDiaryDialog();
              },
              icon: const Icon(Icons.add, color: Colors.black, size: 24),
              label: const Text(
                'Add Entry',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.1),
            AppTheme.secondary.withOpacity(0.1),
          ],
        ),
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.background,
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.primary,
                child: Text(
                  widget.user['name']?[0]?.toUpperCase() ?? '?',
                  style: const TextStyle(
                      fontSize: 36,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user['name'] ?? 'User',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '@${(widget.user['name'] ?? 'user').toLowerCase().replaceAll(' ', '')}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Ratings', stats['ratingsCount'] ?? 0),
              Container(width: 1, height: 40, color: AppTheme.border),
              _buildStatItem('Friends', stats['friendsCount'] ?? 0),
              Container(width: 1, height: 40, color: AppTheme.border),
              _buildStatItem('Badges', stats['badgesCount'] ?? 0),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(),
                  icon:
                      const Icon(Icons.edit, size: 18, color: AppTheme.primary),
                  label: const Text('Edit Profile',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: widget.user['name']);
    final emailCtrl = TextEditingController(text: widget.user['email']);

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
              updateProfile({
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

  Widget _buildStatItem(String label, int value) {
    IconData icon;
    Color color;

    switch (label) {
      case 'Ratings':
        icon = Icons.star;
        color = AppTheme.primary;
        break;
      case 'Friends':
        icon = Icons.people;
        color = AppTheme.secondary;
        break;
      case 'Badges':
        icon = Icons.emoji_events;
        color = Colors.green;
        break;
      default:
        icon = Icons.circle;
        color = AppTheme.textSecondary;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text('$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Ratings'),
          Tab(text: 'Diary'),
          Tab(text: 'Badges'),
          Tab(text: 'Saves'),
          Tab(text: 'Friends'),
        ],
      ),
    );
  }

  // ============ TAB 1: RATINGS ============
  Widget _ratingsTab() {
    if (ratings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.star_border_rounded,
        title: 'No ratings yet',
        subtitle: 'Start rating beverages to build your credibility',
        actionLabel: 'Explore Beverages',
        onAction: () => context.go('/'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length,
      itemBuilder: (_, i) {
        final rating = ratings[i];
        return _buildRatingCard(rating);
      },
    );
  }

  Widget _buildRatingCard(Map rating) {
    final beverage = rating['beverage'] as Map? ?? {};
    final beverageId =
        beverage['id'] ?? rating['beverageId'] ?? rating['beverage_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: beverage['photo'] != null &&
                  beverage['photo'].toString().isNotEmpty
              ? Image.network(beverage['photo'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon())
              : _buildPlaceholderIcon(),
        ),
        title: Text(
          beverage['name'] ?? 'Beverage',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(
                    5,
                    (index) => Icon(
                          index < (rating['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.primary,
                          size: 16,
                        )),
                const SizedBox(width: 12),
                Text(
                  _formatDate(
                      rating['createdAt'] ?? rating['created_at'] ?? ''),
                  style: const TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
            if (rating['comments'] != null &&
                rating['comments'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                rating['comments'],
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        onTap: () {
          if (beverageId != null) {
            context.push('/beverage/$beverageId');
          }
        },
      ),
    );
  }

  // ============ TAB 2: DRINK DIARY ============
  Widget _diaryTab() {
    print('📖 Building diary tab - Entries count: ${diaryEntries.length}');

    if (diaryEntries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.book_outlined,
        title: 'No diary entries yet',
        subtitle: 'Tap the + button below to add your first drink memory',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diaryEntries.length,
      itemBuilder: (_, i) {
        final entry = diaryEntries[i];
        print(
            '📖 Building card for entry $i: ${entry['bevName'] ?? entry['bev_name']}');
        return _buildDiaryCard(entry);
      },
    );
  }

  Widget _buildDiaryCard(Map entry) {
    // ✅ FIX: Handle multiple possible field names from API
    final entryId = entry['entryId'] ?? entry['entryid'] ?? entry['id'];
    final bevName = entry['bevName'] ?? entry['bev_name'] ?? 'Drink';
    final restaurant = entry['restaurant'] ?? '';
    final rating = entry['rating'] ?? 0;
    final notes = entry['notes'] ?? '';
    final image = entry['image'];
    final createdAt = entry['createdAt'] ?? entry['created_at'] ?? '';
    final sharedToFeed =
        entry['sharedToFeed'] ?? entry['shared_to_feed'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: image != null && image.toString().isNotEmpty
              ? Image.network(
                  image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                )
              : _buildPlaceholderIcon(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                bevName,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            if (sharedToFeed == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, size: 10, color: AppTheme.secondary),
                    SizedBox(width: 4),
                    Text('Shared',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (restaurant.isNotEmpty)
              Text(
                restaurant,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(
                    5,
                    (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppTheme.primary,
                          size: 16,
                        )),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(createdAt),
                  style: const TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
          onPressed: () => _confirmDeleteDiary(entryId),
        ),
        onTap: () => _viewDiaryEntry(entry),
      ),
    );
  }

  // ✅ COMPLETE Add Diary Dialog with Camera Integration
  void _showAddDiaryDialog() {
    print('📝 Opening Add Diary Dialog');

    final nameController = TextEditingController();
    final restaurantController = TextEditingController();
    final notesController = TextEditingController();
    int rating = 3;
    bool shareToFeed = false;
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Diary Entry',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo upload
                GestureDetector(
                  onTap: () async {
                    print('📷 Opening camera/gallery picker');

                    final imageUrl = await _cameraService.pickAndUpload(
                      context: context,
                      bucket: 'diary-photos',
                      folder: 'user-${_supabase.auth.currentUser?.id}',
                    );

                    if (imageUrl != null) {
                      print('✅ Photo uploaded: $imageUrl');
                      setDialogState(() {
                        uploadedImageUrl = imageUrl;
                      });
                      _showToast('Photo uploaded successfully');
                    }
                  },
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color: AppTheme.border, style: BorderStyle.solid),
                      image: uploadedImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(uploadedImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: uploadedImageUrl == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo,
                                    color: AppTheme.primary, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text('Add Photo',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('Camera or Gallery',
                                  style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11)),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setDialogState(() {
                                    uploadedImageUrl = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Drink Name *',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: restaurantController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Restaurant / Place',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 2)),
                    suffixIcon:
                        Icon(Icons.search, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Rating',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.primary,
                        size: 36,
                      ),
                      onPressed: () {
                        setDialogState(() => rating = index + 1);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppTheme.primary, width: 2)),
                    helperText: 'Max 200 characters',
                    helperStyle:
                        TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: shareToFeed,
                        onChanged: (v) =>
                            setDialogState(() => shareToFeed = v ?? false),
                        activeColor: AppTheme.secondary,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Share to Feed',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500)),
                            SizedBox(height: 2),
                            Text('Make this visible to your friends',
                                style: TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  _showToast('Please enter drink name', isError: true);
                  return;
                }

                Navigator.pop(context);

                addDiaryEntry(
                  bevName: nameController.text.trim(),
                  restaurant: restaurantController.text.trim(),
                  rating: rating,
                  notes: notesController.text.trim(),
                  image: uploadedImageUrl,
                  sharedToFeed: shareToFeed,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Save Entry',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDiaryEntry(Map entry) {
    final entryId = entry['entryId'] ?? entry['entryid'] ?? entry['id'];
    final bevName = entry['bevName'] ?? entry['bev_name'] ?? 'Drink';
    final restaurant = entry['restaurant'] ?? '';
    final rating = entry['rating'] ?? 0;
    final notes = entry['notes'] ?? '';
    final image = entry['image'];
    final createdAt = entry['createdAt'] ?? entry['created_at'] ?? '';
    final sharedToFeed =
        entry['sharedToFeed'] ?? entry['shared_to_feed'] ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg)),
                child: Image.network(image,
                    height: 240, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 240,
                decoration: const BoxDecoration(
                  color: AppTheme.glassLight,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: const Center(
                  child: Icon(Icons.local_bar_rounded,
                      size: 80, color: AppTheme.textTertiary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bevName,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      if (sharedToFeed == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.secondary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.share,
                                  size: 12, color: AppTheme.secondary),
                              SizedBox(width: 6),
                              Text('Shared',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (restaurant.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          restaurant,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (index) => Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: AppTheme.primary,
                                size: 20,
                              )),
                      const SizedBox(width: 12),
                      Text(
                        _formatDateTime(createdAt),
                        style: const TextStyle(
                            color: AppTheme.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 16),
                    const Text('Notes',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showToast('Edit feature coming soon');
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteDiary(entryId);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }

  void _confirmDeleteDiary(dynamic entryId) {
    if (entryId == null) {
      _showToast('Invalid entry ID', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title:
            const Text('Delete Entry?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
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
              deleteDiaryEntry(entryId.toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============ TAB 3: BADGES ============
  Widget _badgesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              _buildBadgeFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildBadgeFilterChip('Earned', 'earned'),
              const SizedBox(width: 8),
              _buildBadgeFilterChip('In Progress', 'in_progress'),
            ],
          ),
        ),
        Expanded(
          child: _buildBadgesList(),
        ),
      ],
    );
  }

  Widget _buildBadgeFilterChip(String label, String value) {
    final isSelected = badgeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => badgeFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight])
                : null,
            color: isSelected ? null : AppTheme.glassLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
                color: isSelected ? Colors.transparent : AppTheme.border),
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

  final Map<String, List<Map<String, dynamic>>> tierBadges = {
    'Newbie': [
      {
        'name': 'Sip Rookie',
        'icon': '🥤',
        'target': 5,
        'type': 'ratings',
        'description': 'Rate your first 5 drinks'
      },
      {
        'name': 'Introvert',
        'icon': '👋',
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
    'SipZeR': [
      {
        'name': 'Alchemist',
        'icon': '🧪',
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
    'Alpha Z': [
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
        return stats['ratingsCount'] ?? 0;
      case 'friends':
        return stats['friendsCount'] ?? 0;
      case 'bookmarks':
        return bookmarks.length;
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

  Widget _buildBadgesList() {
    final badges = _generateBadges();
    List filteredBadges = badges;

    if (badgeFilter == 'earned') {
      filteredBadges = badges.where((b) => b['earned'] == true).toList();
    } else if (badgeFilter == 'in_progress') {
      filteredBadges = badges.where((b) => b['earned'] == false).toList();
    }

    if (filteredBadges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No badges here',
        subtitle: badgeFilter == 'earned'
            ? 'Keep exploring to earn badges'
            : 'All badges unlocked!',
      );
    }

    final tiers = ['Newbie', 'SipZeR', 'Alpha Z'];
    final tierColors = {
      'Newbie': Colors.green,
      'SipZeR': Colors.blue,
      'Alpha Z': Colors.purple,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: tiers.map((tier) {
        final tierBadges =
            filteredBadges.where((b) => b['tier'] == tier).toList();

        if (tierBadges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tierColors[tier]!.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: tierColors[tier]!.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tier == 'Newbie'
                        ? Icons.stars
                        : tier == 'SipZeR'
                            ? Icons.auto_awesome
                            : Icons.emoji_events,
                    color: tierColors[tier],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tier,
                    style: TextStyle(
                      color: tierColors[tier],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...tierBadges.map((badge) => _buildBadgeCard(badge as Map)),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBadgeCard(Map badge) {
    final earned = badge['earned'] == true;
    final progress = badge['progress'] as int;
    final target = badge['target'] as int;
    final percentage =
        target == 0 ? 0.0 : (progress / target * 100).clamp(0, 100);

    return GestureDetector(
      onTap: () => _showBadgeInfo(badge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: earned ? AppTheme.card : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: earned ? AppTheme.primary.withOpacity(0.5) : AppTheme.border,
            width: earned ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: earned
                    ? const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight])
                    : null,
                color: earned ? null : AppTheme.glassStrong,
                shape: BoxShape.circle,
                boxShadow: earned
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  badge['icon'],
                  style: TextStyle(
                    fontSize: 32,
                    color: earned ? null : Colors.white24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          badge['name'],
                          style: TextStyle(
                            color: earned
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (earned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Unlocked!',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge['description'],
                    style: TextStyle(
                      color: earned
                          ? AppTheme.textSecondary
                          : AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  if (!earned) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$progress/$target',
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeInfo(Map badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: badge['earned'] == true
                    ? const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight])
                    : null,
                color: badge['earned'] == true ? null : AppTheme.glassStrong,
                shape: BoxShape.circle,
                boxShadow: badge['earned'] == true
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  badge['icon'],
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge['name'],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badge['earned'] == true
                    ? AppTheme.primary.withOpacity(0.2)
                    : AppTheme.glassLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge['tier'],
                style: TextStyle(
                  color: badge['earned'] == true
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge['description'],
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (badge['earned'] != true) ...[
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    '${badge['progress']}/${badge['target']}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (badge['progress'] as int) / (badge['target'] as int),
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============ TAB 4: SAVES (BOOKMARKS) ============
  Widget _savesTab() {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No saved spots yet',
        subtitle: 'Bookmark your favorite restaurants for quick access',
        actionLabel: 'Explore Restaurants',
        onAction: () => context.go('/'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) {
        final bookmark = bookmarks[i];
        return _buildBookmarkCard(bookmark);
      },
    );
  }

  Widget _buildBookmarkCard(Map bookmark) {
    final cuisines = bookmark['cuisine'] as List? ?? [];
    final restaurantId = bookmark['restaurantId'] ??
        bookmark['restaurantid'] ??
        bookmark['restaurant_id'];
    final bookmarkId = bookmark['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: bookmark['logoImage'] != null &&
                  bookmark['logoImage'].toString().isNotEmpty
              ? Image.network(bookmark['logoImage'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholderIcon(icon: Icons.restaurant))
              : _buildPlaceholderIcon(icon: Icons.restaurant),
        ),
        title: Text(
          bookmark['name'] ?? 'Restaurant',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  bookmark['area'] ?? '',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
            if (cuisines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: cuisines.take(3).map((cuisine) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      cuisine.toString(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: AppTheme.primary, size: 24),
          onPressed: () => _confirmRemoveBookmark(
              restaurantId?.toString() ?? bookmarkId?.toString() ?? '',
              bookmark['name']),
        ),
        onTap: () {
          if (restaurantId != null) {
            context.push('/restaurant/$restaurantId');
          }
        },
      ),
    );
  }

  void _confirmRemoveBookmark(String restaurantId, String name) {
    if (restaurantId.isEmpty) {
      _showToast('Invalid restaurant ID', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Remove Bookmark?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$name" from your saved restaurants?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              removeBookmark(restaurantId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============ TAB 5: FRIENDS ============
  Widget _friendsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showToast('Add from contacts coming soon'),
                  icon: const Icon(Icons.contact_phone, size: 18),
                  label: const Text('Phone Book'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showFriendSearch(),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search Friends'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: friends.isEmpty
              ? _buildEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No friends yet',
                  subtitle: 'Connect with other SipZy users',
                  actionLabel: 'Find Friends',
                  onAction: () => _showToast('Friend search coming soon'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: friends.length,
                  itemBuilder: (_, i) {
                    final friend = friends[i];
                    return _buildFriendCard(friend);
                  },
                ),
        ),
      ],
    );
  }

  void _showFriendSearch() async {
    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        String searchText = '';
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text('Search Friends',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (v) => searchText = v,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter name or phone',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, searchText),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child:
                  const Text('Search', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );

    if (query != null && query.isNotEmpty) {
      try {
        final results = await _userService.searchFriends(query);
        if (results.isNotEmpty) {
          _showSearchResults(results);
        } else {
          _showToast('No users found');
        }
      } catch (e) {
        _showToast('Search failed', isError: true);
      }
    }
  }

  void _showSearchResults(List results) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Search Results',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final person = results[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondary,
                        child: Text(person['name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(person['name'],
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(person['phone'] ?? person['email'] ?? '',
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add,
                            color: AppTheme.primary),
                        onPressed: () async {
                          final success = await _userService
                              .addFriend(person['id'].toString());
                          if (success) {
                            Navigator.pop(context);
                            _showToast('Friend added!');
                            fetchAll();
                          } else {
                            _showToast('Failed to add friend', isError: true);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Map friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.background,
            child: friend['avatar'] != null &&
                    friend['avatar'].toString().isNotEmpty
                ? ClipOval(
                    child: Image.network(friend['avatar'],
                        width: 56, height: 56, fit: BoxFit.cover))
                : Text(
                    friend['name'][0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
          ),
        ),
        title: Text(
          friend['name'] ?? 'User',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${friend['username'] ?? 'user'}',
              style:
                  const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
            if (friend['mutualFriends'] != null &&
                friend['mutualFriends'] > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${friend['mutualFriends']} mutual friends',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
        onTap: () {
          _showToast('View profile coming soon');
        },
      ),
    );
  }

  // ============ SHARED WIDGETS ============
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.card,
            highlightColor: AppTheme.glassLight,
            child: Column(
              children: [
                const CircleAvatar(radius: 48, backgroundColor: AppTheme.card),
                const SizedBox(height: 16),
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            AppTheme.gradientButtonAmber(
                onPressed: fetchAll, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    Colors.transparent
                  ],
                ),
              ),
              child: Icon(icon, size: 64, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppTheme.gradientButtonAmber(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon({IconData? icon}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon ?? Icons.local_bar_rounded,
          color: AppTheme.textTertiary, size: 28),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
