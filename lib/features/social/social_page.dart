import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';
import '../../shared/navigation/bottom_nav.dart';

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

  late TabController _tabController;

  bool loading = true;
  bool hasError = false;

  // User stats from badges table
  Map<String, dynamic> stats = {
    'ratingsCount': 0,
    'friendsCount': 0,
    'bookmarkCount': 0,
  };

  List diaryEntries = [];
  List bookmarks = [];
  List friends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getHeaders() async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    final headers = {'Content-Type': 'application/json'};

    if (session?.accessToken != null) {
      headers['Authorization'] = 'Bearer ${session!.accessToken}';
      print('🔑 FULL TOKEN: ${session.accessToken}');
    }

    final effectiveUserId = user?.id ?? widget.user['id']?.toString();
    if (effectiveUserId != null) {
      headers['x-user-id'] = effectiveUserId;
    }

    return headers;
  }

  Future<void> fetchAll() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final headers = await _getHeaders();

      print('📡 Fetching social data with headers: ${headers.keys.join(", ")}');

      // Using correct endpoints matching backend routes
      final responses = await Future.wait([
        // GET /users/me - user profile + badge stats
        http
            .get(
              Uri.parse('${EnvConfig.apiBaseUrl}/users/me'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),

        // GET /diary - all diary entries for current user
        http
            .get(
              Uri.parse('${EnvConfig.apiBaseUrl}/diary'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),

        // GET /users/me/bookmarks - user bookmarks
        http
            .get(
              Uri.parse('${EnvConfig.apiBaseUrl}/users/me/bookmarks'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),

        // GET /users/me/friends - user friends
        http
            .get(
              Uri.parse('${EnvConfig.apiBaseUrl}/friends'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
      ]);

      // Check for auth error in any response
      for (int i = 0; i < responses.length; i++) {
        final res = responses[i];
        print('Response $i status: ${res.statusCode}');
        if (res.statusCode == 401) {
          if (mounted) {
            _toast('Session expired. Please login again.', isError: true);
            context.go('/auth');
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          // Parse user/stats data (from badges table)
          final userData = _safeParseJson(responses[0].body, defaultValue: {});

          // Try to extract badge stats
          final badges = userData['badges'] ?? {};
          stats = {
            'ratingsCount': badges['ratingscount'] ??
                badges['ratingsCount'] ??
                userData['ratingscount'] ??
                userData['ratingsCount'] ??
                0,
            'friendsCount': badges['friendscount'] ??
                badges['friendsCount'] ??
                userData['friendscount'] ??
                userData['friendsCount'] ??
                0,
            'bookmarkCount': badges['bookmarkcount'] ??
                badges['bookmarkCount'] ??
                userData['bookmarkcount'] ??
                userData['bookmarkCount'] ??
                0,
          };

          diaryEntries = _safeParseArray(responses[1].body);
          bookmarks = _safeParseArray(responses[2].body);
          friends = _safeParseArray(responses[3].body);
          hasError = false;
        });
      }
    } on TimeoutException {
      print('❌ Request timeout in fetchAll');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Request timed out. Please try again.', isError: true);
      }
    } catch (e) {
      print('❌ Social fetchAll error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load profile data', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  dynamic _safeParseJson(String body, {dynamic defaultValue}) {
    try {
      final data = jsonDecode(body);
      return data['success'] == true ? (data['data'] ?? defaultValue) : data;
    } catch (e) {
      print('JSON parse error: $e');
      return defaultValue;
    }
  }

  List _safeParseArray(String body) {
    try {
      final data = jsonDecode(body);
      if (data['success'] == true) {
        return (data['data'] as List? ?? []);
      } else if (data is List) {
        return data;
      } else {
        return [];
      }
    } catch (e) {
      print('Array parse error: $e');
      return [];
    }
  }

  // ---------------- Diary CRUD ----------------

  Future<void> addDiary({
    required String bevName,
    required String restaurant,
    required int rating,
    String? notes,
    String? image,
  }) async {
    if (bevName.isEmpty || restaurant.isEmpty || rating < 1 || rating > 5) {
      _toast('Please fill all required fields correctly', isError: true);
      return;
    }

    try {
      final headers = await _getHeaders();

      // POST /diary - backend route
      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}/diary'),
            headers: headers,
            body: jsonEncode({
              'bevName': bevName,
              'restaurant': restaurant,
              'rating': rating,
              'notes': notes ?? '',
              'image': image ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Add diary response: ${response.statusCode}');

      if (response.statusCode == 401) {
        _toast('Session expired. Please login again.', isError: true);
        context.go('/auth');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _toast('Diary entry added');
        fetchAll();
      } else {
        _toast('Failed to add diary entry', isError: true);
      }
    } on TimeoutException {
      _toast('Request timed out', isError: true);
    } catch (e) {
      print('Add diary error: $e');
      _toast('Error adding diary', isError: true);
    }
  }

  Future<void> updateDiary(String entryId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();

      // PATCH /diary/:entryId
      final response = await http
          .patch(
            Uri.parse('${EnvConfig.apiBaseUrl}/diary/$entryId'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 15));

      print('Update diary response: ${response.statusCode}');

      if (response.statusCode == 401) {
        _toast('Session expired. Please login again.', isError: true);
        context.go('/auth');
        return;
      }

      if (response.statusCode == 200) {
        _toast('Diary updated');
        fetchAll();
      } else {
        _toast('Failed to update diary', isError: true);
      }
    } on TimeoutException {
      _toast('Request timed out', isError: true);
    } catch (e) {
      print('Update diary error: $e');
      _toast('Error updating diary', isError: true);
    }
  }

  Future<void> deleteDiary(String entryId) async {
    try {
      final headers = await _getHeaders();

      // DELETE /diary/:entryId
      final response = await http
          .delete(
            Uri.parse('${EnvConfig.apiBaseUrl}/diary/$entryId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('Delete diary response: ${response.statusCode}');

      if (response.statusCode == 401) {
        _toast('Session expired. Please login again.', isError: true);
        context.go('/auth');
        return;
      }

      if (response.statusCode == 200) {
        _toast('Diary deleted');
        fetchAll();
      } else {
        _toast('Failed to delete diary', isError: true);
      }
    } on TimeoutException {
      _toast('Request timed out', isError: true);
    } catch (e) {
      print('Delete diary error: $e');
      _toast('Error deleting diary', isError: true);
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();

      final isCurrentlyBookmarked = bookmarks.any(
        (b) =>
            b['restaurantid']?.toString() == restaurantId ||
            b['restaurantId']?.toString() == restaurantId ||
            b['id']?.toString() == restaurantId,
      );

      http.Response response;

      if (isCurrentlyBookmarked) {
        // DELETE /bookmarks/:restaurantId
        response = await http
            .delete(
              Uri.parse('${EnvConfig.apiBaseUrl}/bookmarks/$restaurantId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
      } else {
        // POST /bookmarks/:restaurantId
        response = await http
            .post(
              Uri.parse('${EnvConfig.apiBaseUrl}/bookmarks/$restaurantId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401) {
        _toast('Session expired. Please login again.', isError: true);
        context.go('/auth');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _toast(isCurrentlyBookmarked ? 'Bookmark removed' : 'Bookmarked!');
        fetchAll();
      }
    } on TimeoutException {
      _toast('Request timed out', isError: true);
    } catch (e) {
      print('Toggle bookmark error: $e');
      _toast('Error updating bookmark', isError: true);
    }
  }

  void logout() {
    widget.onLogout();
    context.go('/auth');
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: _buildLoadingSkeleton(),
        ),
        bottomNavigationBar: const BottomNav(active: 'social'),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: _buildErrorState(),
        ),
        bottomNavigationBar: const BottomNav(active: 'social'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchAll,
          color: AppTheme.primary,
          backgroundColor: AppTheme.card,
          child: Column(
            children: [
              _header(),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'Diary'),
                  Tab(text: 'Saves'),
                  Tab(text: 'Friends'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _diaryTab(),
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: _showAddDiaryDialog,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  void _showAddDiaryDialog() {
    final nameController = TextEditingController();
    final restaurantController = TextEditingController();
    final notesController = TextEditingController();
    int rating = 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text('Add Diary Entry',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Beverage Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restaurantController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Restaurant',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rating: ',
                        style: TextStyle(color: Colors.white)),
                    ...List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppTheme.primary,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = index + 1);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                addDiary(
                  bevName: nameController.text,
                  restaurant: restaurantController.text,
                  rating: rating,
                  notes: notesController.text,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: AppTheme.card,
            highlightColor: AppTheme.glassLight,
            child: const CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.card,
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: AppTheme.card,
            highlightColor: AppTheme.glassLight,
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppTheme.gradientButtonAmber(
              onPressed: fetchAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            child: Text(
              widget.user['name']?[0]?.toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 28, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user['name'] ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            widget.user['phone'] ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('Ratings', stats['ratingsCount'] ?? 0),
              _stat('Friends', stats['friendsCount'] ?? 0),
              _stat('Saves', stats['bookmarkCount'] ?? 0),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _diaryTab() {
    if (diaryEntries.isEmpty) {
      return Center(
        child: Text('No diary entries yet',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diaryEntries.length,
      itemBuilder: (_, i) {
        final entry = diaryEntries[i];
        final entryId = entry['entryid'] ?? entry['entryId'];
        final bevName = entry['bevname'] ?? entry['bevName'] ?? 'Unknown';
        final restaurant = entry['restaurant'] ?? '';
        final rating = entry['rating'] ?? 0;
        final notes = entry['notes'] ?? '';
        final image = entry['image'];

        return Card(
          color: AppTheme.card,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: image != null && image.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Image.network(
                      image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_bar_rounded,
                          color: AppTheme.textSecondary),
                    ),
                  )
                : const Icon(Icons.local_bar_rounded,
                    color: AppTheme.textSecondary),
            title: Text(
              bevName,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (notes.isNotEmpty)
                  Text(
                    notes,
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$rating',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.star, color: AppTheme.primary, size: 16),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => deleteDiary(entryId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _savesTab() {
    if (bookmarks.isEmpty) {
      return Center(
        child: Text('No bookmarks yet',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) {
        final bookmark = bookmarks[i];
        final name = bookmark['name'] ?? 'Restaurant';
        final address = bookmark['address'] ?? '';
        final logoImage = bookmark['logoimage'] ?? bookmark['logoImage'];

        return Card(
          color: AppTheme.card,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: logoImage != null && logoImage.toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Image.network(
                      logoImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.restaurant_rounded,
                          color: AppTheme.textSecondary),
                    ),
                  )
                : const Icon(Icons.restaurant_rounded,
                    color: AppTheme.textSecondary),
            title: Text(
              name,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              address,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _friendsTab() {
    if (friends.isEmpty) {
      return Center(
        child: Text('No friends yet',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (_, i) {
        final friend = friends[i];
        final name = friend['name'] ?? 'User';
        final phone = friend['phone'] ?? '';

        return Card(
          color: AppTheme.card,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondary,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: Text(
              phone,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      },
    );
  }
}
