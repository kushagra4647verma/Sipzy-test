import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../config/env_config.dart';

class EventsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EventsPage({super.key, required this.user});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const api = EnvConfig.apiBaseUrl;

  List events = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => loading = true);
    try {
      final query = searchQuery.isNotEmpty ? '?search=$searchQuery' : '';
      final res = await http.get(Uri.parse('$api/events$query'));
      setState(() => events = jsonDecode(res.body));
    } catch (_) {
      _toast('Failed to load events');
    } finally {
      setState(() => loading = false);
    }
  }

  void bookNow(Map event) async {
    final uri = Uri.parse('tel:+918012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _toast('Booking for ${event['name']}...');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final featured = events.where((e) => e['featured'] == true).toList();
    final trending = events
        .where((e) => e['trending'] == true && e['featured'] != true)
        .toList();
    final more = events
        .where((e) => e['featured'] != true && e['trending'] != true)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? _loadingSkeleton()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (featured.isNotEmpty)
                          _section(
                            'Featured Events',
                            featured,
                            tag: 'Featured',
                          ),
                        if (trending.isNotEmpty)
                          _section(
                            'Trending Near You',
                            trending,
                            tag: 'Trending',
                          ),
                        if (more.isNotEmpty) _section('More Events', more),
                        if (events.isEmpty) _emptyState(),
                      ],
                    ),
                  ),
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
              Icon(Icons.calendar_month, color: Colors.purple, size: 28),
              SizedBox(width: 8),
              Text(
                'EventS',
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
            'Discover exciting events near you',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) {
              searchQuery = v;
              fetchEvents();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search events...',
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

  Widget _section(String title, List list, {String? tag}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...list.map((event) => _eventCard(event, tag: tag)),
      ],
    );
  }

  Widget _eventCard(Map event, {String? tag}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  event['image'],
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (tag != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: tag == 'Featured' ? Colors.amber : Colors.purple,
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: tag == 'Featured' ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event['description'],
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['date'],
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['location'],
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => bookNow(event),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        tag == 'Trending' ? Colors.purple : Colors.amber,
                    foregroundColor:
                        tag == 'Trending' ? Colors.white : Colors.black,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 240,
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
            Icon(Icons.calendar_month, size: 64, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'No events found',
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
      currentIndex: 2,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.amber,
      unselectedItemColor: Colors.white60,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.wine_bar), label: 'Discover'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
      ],
    );
  }
}
