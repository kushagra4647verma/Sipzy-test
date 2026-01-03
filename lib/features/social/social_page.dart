import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class SocialPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const SocialPage({super.key, required this.user, required this.onLogout});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  static const API = String.fromEnvironment('API_URL');

  late TabController _tabController;

  bool loading = true;

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
    setState(() => loading = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$API/users/${widget.user['id']}/stats')),
        http.get(Uri.parse('$API/users/${widget.user['id']}/ratings')),
        http.get(Uri.parse('$API/diary/${widget.user['id']}')),
        http.get(Uri.parse('$API/users/${widget.user['id']}/badges')),
        http.get(Uri.parse('$API/bookmarks/${widget.user['id']}')),
        http.get(Uri.parse('$API/friends/${widget.user['id']}')),
      ]);

      if (mounted) {
        setState(() {
          stats = jsonDecode(responses[0].body);
          ratings = jsonDecode(responses[1].body);
          diaryEntries = jsonDecode(responses[2].body);
          badges = jsonDecode(responses[3].body);
          bookmarks = jsonDecode(responses[4].body);
          friends = jsonDecode(responses[5].body);
        });
      }
    } catch (_) {
      _toast('Failed to load profile data');
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
      _toast('Fill all required fields');
      return;
    }

    await http.post(
      Uri.parse('$API/diary/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': widget.user['id'], ...diaryForm}),
    );

    _toast('Diary entry added');
    resetDiary();
    fetchAll();
  }

  Future<void> updateDiary() async {
    await http.put(
      Uri.parse('$API/diary/entry/${selectedDiary!['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(diaryForm),
    );

    _toast('Diary updated');
    resetDiary();
    fetchAll();
  }

  Future<void> deleteDiary() async {
    await http.delete(Uri.parse('$API/diary/entry/${selectedDiary!['id']}'));

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
      Uri.parse('$API/diary/upload-photo'),
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

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _header(),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white60,
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
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              backgroundColor: Colors.amber,
              onPressed: () => setState(() => showAddDiary = true),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
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
            backgroundColor: Colors.amber,
            child: Text(
              widget.user['name'][0].toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.user['name'],
            style: const TextStyle(color: Colors.white, fontSize: 22),
          ),
          Text(
            '@${widget.user['name'].toLowerCase().replaceAll(' ', '')}',
            style: const TextStyle(color: Colors.white60),
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
          ElevatedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }

  // ---------------- Tabs ----------------

  Widget _ratingsTab() {
    if (ratings.isEmpty) {
      return const Center(
        child: Text('No ratings yet', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView.builder(
      itemCount: ratings.length,
      itemBuilder: (_, i) {
        final r = ratings[i];
        return ListTile(
          leading: r['beverage']?['image'] != null
              ? Image.network(
                  r['beverage']['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.local_bar, color: Colors.white),
          title: Text(
            r['beverage']?['name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            r['review'] ?? '',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            '${r['rating']} ⭐',
            style: const TextStyle(color: Colors.amber),
          ),
        );
      },
    );
  }

  Widget _diaryTab() {
    if (diaryEntries.isEmpty) {
      return const Center(
        child: Text(
          'No diary entries',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return ListView.builder(
      itemCount: diaryEntries.length,
      itemBuilder: (_, i) {
        final d = diaryEntries[i];
        return ListTile(
          leading: d['photo'] != null && d['photo'].toString().isNotEmpty
              ? Image.network(
                  d['photo'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.local_bar, color: Colors.white),
          title: Text(
            d['beverage_name'] ?? 'Unknown',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            d['restaurant'] ?? '',
            style: const TextStyle(color: Colors.white60),
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
              ? Colors.amber.withOpacity(.3)
              : Colors.grey[900],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b['icon'] ?? '🏆', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                b['name'] ?? 'Badge',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _savesTab() {
    if (bookmarks.isEmpty) {
      return const Center(
        child: Text('No bookmarks', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView(
      children: bookmarks
          .map(
            (r) => ListTile(
              leading: r['image'] != null
                  ? Image.network(
                      r['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.restaurant, color: Colors.white),
              title: Text(
                r['name'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                r['area'] ?? '',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _friendsTab() {
    if (friends.isEmpty) {
      return const Center(
        child: Text('No friends yet', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView(
      children: friends
          .map(
            (f) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple,
                child: Text(
                  f['name']?[0]?.toUpperCase() ?? 'F',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                f['name'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '@${f['name']?.toLowerCase()?.replaceAll(' ', '') ?? 'unknown'}',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          )
          .toList(),
    );
  }
}
