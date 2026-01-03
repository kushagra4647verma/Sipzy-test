import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../shared/ui/share_modal.dart';
import '../../shared/ui/invite_friends_modal.dart';
import '../../shared/ui/group_mix_magic.dart';

class RestaurantDetail extends StatefulWidget {
  final Map<String, dynamic> user;
  final String restaurantId;

  const RestaurantDetail({
    super.key,
    required this.user,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetail> createState() => _RestaurantDetailState();
}

class _RestaurantDetailState extends State<RestaurantDetail> {
  static const API = String.fromEnvironment('API_URL');

  Map<String, dynamic>? restaurant;
  List beverages = [];
  List filteredBeverages = [];

  bool loading = true;
  bool alcoholicOnly = true;
  bool isBookmarked = false;

  String searchQuery = '';
  String sortBy = 'recommended';
  String menuTab = 'beverages';

  bool showSort = false;
  bool showShare = false;
  bool showInvite = false;
  bool showGroupMix = false;

  Map<String, dynamic>? shareItem;

  @override
  void initState() {
    super.initState();
    _resetState();
    fetchRestaurant();
    checkBookmark();
  }

  void _resetState() {
    alcoholicOnly = true;
    searchQuery = '';
    sortBy = 'recommended';
    menuTab = 'beverages';
  }

  Future<void> fetchRestaurant() async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse('$API/restaurants/${widget.restaurantId}'),
      );
      final data = jsonDecode(res.body);

      setState(() {
        restaurant = data;
        beverages = data['beverages'] ?? [];
      });

      filterAndSort();
    } catch (_) {
      _toast('Failed to load restaurant');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> checkBookmark() async {
    final res = await http.get(
      Uri.parse(
        '$API/bookmarks/check/${widget.user['id']}/${widget.restaurantId}',
      ),
    );
    final data = jsonDecode(res.body);
    setState(() => isBookmarked = data['bookmarked']);
  }

  Future<void> toggleBookmark() async {
    final res = await http.post(
      Uri.parse('$API/bookmarks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.user['id'],
        'restaurant_id': widget.restaurantId,
      }),
    );

    final data = jsonDecode(res.body);
    setState(() => isBookmarked = data['bookmarked']);

    _toast(data['bookmarked'] ? 'Bookmarked!' : 'Bookmark removed');
  }

  void filterAndSort() {
    List list = beverages
        .where((b) => b['alcoholic'] == alcoholicOnly)
        .toList();

    if (searchQuery.isNotEmpty) {
      list = list
          .where(
            (b) =>
                b['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
                b['type'].toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (sortBy == 'price_low') {
      list.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (sortBy == 'price_high') {
      list.sort((a, b) => b['price'].compareTo(a['price']));
    } else {
      list.sort(
        (a, b) => (b['sipzy_rating'] ?? 0).compareTo(a['sipzy_rating'] ?? 0),
      );
    }

    setState(() => filteredBeverages = list);
  }

  void openMaps() async {
    final lat = restaurant!['lat'];
    final lon = restaurant!['lon'];
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );
    await launchUrl(url);
  }

  void callRestaurant() async {
    final phone = restaurant!['phone'];
    await launchUrl(Uri.parse('tel:$phone'));
  }

  void shareBeverage(Map bev) {
    setState(() {
      shareItem = {
        'title': bev['name'],
        'description':
            '${bev['type']} • ₹${bev['price']} • ${restaurant!['name']}',
      };
      showShare = true;
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (restaurant == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [_content(), if (showSort) _sortSheet()]),
    );
  }

  // ---------------- UI ----------------

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _header(),
        _toggleSearchSort(),
        Padding(padding: const EdgeInsets.all(16), child: _menuSection()),
      ],
    );
  }

  Widget _header() {
    return Stack(
      children: [
        Image.network(
          restaurant!['image'],
          height: 320,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          height: 320,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
              Row(
                children: [
                  _circleBtn(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    toggleBookmark,
                  ),
                  _circleBtn(
                    Icons.group,
                    () => setState(() => showInvite = true),
                  ),
                  _circleBtn(Icons.call, callRestaurant),
                  _circleBtn(Icons.map, openMaps),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant!['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant!['cuisine'].join(' • '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              _surpriseBtn(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _surpriseBtn() {
    return InkWell(
      onTap: () => setState(() => showGroupMix = true),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.purple, Colors.pink]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _toggleSearchSort() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Switch(
            value: alcoholicOnly,
            onChanged: (v) {
              setState(() => alcoholicOnly = v);
              filterAndSort();
            },
          ),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search beverages...',
              ),
              onChanged: (v) {
                searchQuery = v;
                filterAndSort();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => setState(() => showSort = true),
          ),
        ],
      ),
    );
  }

  Widget _menuSection() {
    if (menuTab == 'food') {
      return _foodMenu();
    }

    if (filteredBeverages.isEmpty) {
      return const Center(
        child: Text(
          'No beverages found',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: filteredBeverages.length,
      itemBuilder: (_, i) => _beverageCard(filteredBeverages[i]),
    );
  }

  Widget _beverageCard(Map bev) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/beverage/${bev['id']}'),
      child: Container(
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
                    bev['image'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _circleBtn(Icons.share, () => shareBeverage(bev)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bev['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    bev['type'],
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${bev['price']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodMenu() {
    final photos = restaurant!['photos'] ?? [];

    if (photos.isEmpty) {
      return const Center(
        child: Text(
          'No menu photos available',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Column(
      children: photos
          .map<Widget>(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.network(p),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _sortSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption('recommended', 'Recommended'),
            _sortOption('price_low', 'Price: Low to High'),
            _sortOption('price_high', 'Price: High to Low'),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String value, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: sortBy == value
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() {
          sortBy = value;
          showSort = false;
        });
        filterAndSort();
      },
    );
  }
}
