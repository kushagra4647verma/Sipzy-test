import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GamesPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const GamesPage({super.key, required this.user});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  static const api = String.fromEnvironment('API_URL');

  List games = [];
  String searchQuery = '';
  bool loading = true;

  final Map<String, String> iconMap = {
    'brain': '🧠',
    'flask': '🧪',
    'sparkles': '✨',
    'disc': '💿',
    'users': '👥',
  };

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    setState(() => loading = true);
    try {
      final query = searchQuery.isNotEmpty ? '?search=$searchQuery' : '';
      final res = await http.get(Uri.parse('$api/games$query'));
      setState(() => games = jsonDecode(res.body));
    } catch (_) {
      _toast('Failed to load games');
    } finally {
      setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? _loadingGrid()
                : games.isNotEmpty
                ? _gamesGrid()
                : _emptyState(),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------------- UI ----------------

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gamepad, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text(
                'GameS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Fun games to play while you sip',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) {
              searchQuery = v;
              fetchGames();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search games...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gamesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: games.length,
      itemBuilder: (_, i) {
        final game = games[i];
        return _gameCard(game);
      },
    );
  }

  Widget _gameCard(Map game) {
    final icon = iconMap[game['icon']] ?? '🎮';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            game['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            game['description'],
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          Divider(color: Colors.white12),
          const SizedBox(height: 6),
          const Text(
            'How to Play:',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game['instructions'],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _loadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: const [
            Icon(Icons.gamepad, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'No games found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 3,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.white60,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.wine_bar), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Games'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
      ],
    );
  }
}
