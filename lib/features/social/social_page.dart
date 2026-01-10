import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/env_config.dart';
import '../../core/theme/app_theme.dart';

class SocialPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const SocialPage({super.key, required this.user, required this.onLogout});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  static const api = EnvConfig.apiBaseUrl;

  late TabController _tabController;

  bool loading = true;
  bool hasError = false;

  Map<String, dynamic> stats = {
    'ratings_count': 0,
    'friends_count': 0,
    'bookmarks_count': 0,
  };

  List ratings = [];
  List diaryEntries = [];
  List badges = [];
  List bookmarks = [];
  List friends = [];

  // Diary state
  bool showAddDiary = false;
  bool showEditDiary = false;
  Map<String, dynamic>? selectedDiary;

  Map<String, dynamic> diaryForm = {
    'beverage_name': '',
    'restaurant': '',
    'rating': 0,
    'notes': '',
    'photo': '',
    'share_to_feed': false,
  };

  String badgeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      final responses = await Future.wait([
        http.get(Uri.parse('$api/users/${widget.user['id']}/stats')),
        http.get(Uri.parse('$api/users/${widget.user['id']}/ratings')),
        http.get(Uri.parse('$api/diary/${widget.user['id']}')),
        http.get(Uri.parse('$api/users/${widget.user['id']}/badges')),
        http.get(Uri.parse('$api/bookmarks/${widget.user['id']}')),
        http.get(Uri.parse('$api/friends/${widget.user['id']}')),
      ]);

      if (mounted) {
        setState(() {
          stats = jsonDecode(responses[0].body);
          ratings = jsonDecode(responses[1].body);
          diaryEntries = jsonDecode(responses[2].body);
          badges = jsonDecode(responses[3].body);
          bookmarks = jsonDecode(responses[4].body);
          friends = jsonDecode(responses[5].body);
          hasError = false;
        });
      }
    } catch (e) {
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

  // ---------------- Diary CRUD ----------------

  Future<void> addDiary() async {
    if (diaryForm['beverage_name'].isEmpty ||
        diaryForm['restaurant'].isEmpty ||
        diaryForm['rating'] == 0) {
      _toast('Fill all required fields', isError: true);
      return;
    }

    await http.post(
      Uri.parse('$api/diary/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.user['id'], ...diaryForm}),
    );

    _toast('Diary entry added');
    resetDiary();
    fetchAll();
  }

  Future<void> updateDiary() async {
    await http.put(
      Uri.parse('$api/diary/entry/${selectedDiary!['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(diaryForm),
    );

    _toast('Diary updated');
    resetDiary();
    fetchAll();
  }

  Future<void> deleteDiary() async {
    await http.delete(Uri.parse('$api/diary/entry/${selectedDiary!['id']}'));

    _toast('Diary deleted');
    resetDiary();
    fetchAll();
  }

  Future<void> uploadDiaryPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$api/diary/upload-photo'),
    );
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final res = await req.send();
    if (res.statusCode == 200) {
      final body = jsonDecode(await res.stream.bytesToString());
      setState(() => diaryForm['photo'] = body['photo_url']);
    }
  }

  void resetDiary() {
    setState(() {
      showAddDiary = false;
      showEditDiary = false;
      selectedDiary = null;
      diaryForm = {
        'beverage_name': '',
        'restaurant': '',
        'rating': 0,
        'notes': '',
        'photo': '',
        'share_to_feed': false,
      };
    });
  }

  void logout() {
    widget.onLogout();
    context.go('/auth');
  }

  void _toast(String msg, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red.shade600 : AppTheme.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: _buildLoadingSkeleton(),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
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
                Tab(text: 'Ratings'),
                Tab(text: 'Diary'),
                Tab(text: 'Badges'),
                Tab(text: 'Saves'),
                Tab(text: 'Friends'),
              ],
            ),
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
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => setState(() => showAddDiary = true),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
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
            child: CircleAvatar(
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
            Icon(
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

  // ---------------- Header ----------------

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary,
            child: Text(
              widget.user['name'][0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user['name'],
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '@${widget.user['name'].toLowerCase().replaceAll(' ', '')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('Ratings', stats['ratings_count'] ?? 0),
              _stat('Friends', stats['friends_count'] ?? 0),
              _stat('Badges', badges.where((b) => b['earned'] == true).length),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
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

  // ---------------- Tabs ----------------

  Widget _ratingsTab() {
    if (ratings.isEmpty) {
      return Center(
        child: Text('No ratings yet',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView.builder(
      itemCount: ratings.length,
      itemBuilder: (_, i) {
        final r = ratings[i];
        return ListTile(
          leading: r['beverage']?['image'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Image.network(
                    r['beverage']['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.local_bar_rounded, color: AppTheme.textSecondary),
          title: Text(
            r['beverage']?['name'] ?? 'Unknown',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            r['review'] ?? '',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          trailing: Text(
            '${r['rating']} ⭐',
            style: const TextStyle(color: AppTheme.primary),
          ),
        );
      },
    );
  }

  Widget _diaryTab() {
    if (diaryEntries.isEmpty) {
      return Center(
        child: Text(
          'No diary entries',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      itemCount: diaryEntries.length,
      itemBuilder: (_, i) {
        final d = diaryEntries[i];
        return ListTile(
          leading: d['photo'] != null && d['photo'].toString().isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Image.network(
                    d['photo'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.local_bar_rounded, color: AppTheme.textSecondary),
          title: Text(
            d['beverage_name'] ?? 'Unknown',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            d['restaurant'] ?? '',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          onTap: () {
            setState(() {
              selectedDiary = d;
              diaryForm = Map<String, dynamic>.from(d);
              showEditDiary = true;
            });
          },
        );
      },
    );
  }

  Widget _badgesTab() {
    final filtered = badges.where((b) {
      if (badgeFilter == 'earned') return b['earned'] == true;
      if (badgeFilter == 'in_progress') return b['earned'] != true;
      return true;
    }).toList();

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(12),
      children: filtered.map((b) {
        return Card(
          color: b['earned'] == true
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.card,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b['icon'] ?? '🏆', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                b['name'] ?? 'Badge',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _savesTab() {
    if (bookmarks.isEmpty) {
      return Center(
        child:
            Text('No bookmarks', style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView(
      children: bookmarks
          .map(
            (r) => ListTile(
              leading: r['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Image.network(
                        r['image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.restaurant_rounded,
                      color: AppTheme.textSecondary),
              title: Text(
                r['name'] ?? 'Unknown',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                r['area'] ?? '',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _friendsTab() {
    if (friends.isEmpty) {
      return Center(
        child: Text('No friends yet',
            style: Theme.of(context).textTheme.bodySmall),
      );
    }

    return ListView(
      children: friends
          .map(
            (f) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.secondary,
                child: Text(
                  f['name']?[0]?.toUpperCase() ?? 'F',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                f['name'] ?? 'Unknown',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                '@${f['name']?.toLowerCase()?.replaceAll(' ', '') ?? 'unknown'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
          .toList(),
    );
  }
}
