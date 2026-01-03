import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../shared/navigation/bottom_nav.dart';
import '../../core/theme/colors.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const api = String.fromEnvironment('API_URL');

  // data
  List restaurants = [];
  List featuredRestaurants = [];
  List trendingRestaurants = [];
  List<int> bookmarkedIds = [];

  // ui state
  bool loading = true;
  bool showFilters = false;
  String searchQuery = '';
  String sortBy = 'rating';

  // filters
  List<String> selectedCuisines = [];
  List<String> selectedBaseDrinks = [];
  List<String> selectedTypes = [];
  double rating = 0;
  double distance = 10;
  RangeValues cost = const RangeValues(0, 5000);

  // share
  Map<String, dynamic>? shareItem;

  final cuisines = [
    'Indian',
    'Continental',
    'Asian',
    'Mediterranean',
    'Italian',
    'Chinese',
  ];
  final baseDrinks = ['Whisky', 'Rum', 'Vodka', 'Gin', 'Beer', 'Wine'];
  final restaurantTypes = [
    'Fine Dining',
    'Casual',
    'Romantic',
    'Gastropub',
    'Brewery',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([fetchRestaurants(), fetchBookmarks()]);
  }

  Future<void> fetchRestaurants() async {
    setState(() => loading = true);

    final query = <String, String>{
      if (searchQuery.isNotEmpty) 'search': searchQuery,
      if (selectedCuisines.isNotEmpty) 'cuisine': selectedCuisines.first,
      if (rating > 0) 'min_rating': rating.toString(),
      if (distance < 10) 'max_distance': distance.toString(),
      if (selectedTypes.isNotEmpty) 'restaurant_type': selectedTypes.first,
      if (cost.start > 0) 'min_cost': cost.start.toInt().toString(),
      if (cost.end < 5000) 'max_cost': cost.end.toInt().toString(),
      'sort_by': sortBy,
    };

    final uri = Uri.parse('$api/restaurants').replace(queryParameters: query);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      restaurants = jsonDecode(res.body);
    }

    if (searchQuery.isEmpty && !_hasActiveFilters) {
      featuredRestaurants = await _fetchList('$api/restaurants/featured');
      trendingRestaurants = await _fetchList('$api/restaurants/trending');
    }

    setState(() => loading = false);
  }

  Future<List> _fetchList(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<void> fetchBookmarks() async {
    final res = await http.get(
      Uri.parse('$api/bookmarks/${widget.user['id']}'),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        bookmarkedIds = decoded.map((e) => (e['id'] as num).toInt()).toList();
      }
    }
  }

  bool get _hasActiveFilters =>
      selectedCuisines.isNotEmpty ||
      selectedBaseDrinks.isNotEmpty ||
      selectedTypes.isNotEmpty ||
      rating > 0 ||
      distance < 10 ||
      cost.start > 0 ||
      cost.end < 5000;

  void clearFilters() {
    setState(() {
      selectedCuisines.clear();
      selectedBaseDrinks.clear();
      selectedTypes.clear();
      rating = 0;
      distance = 10;
      cost = const RangeValues(0, 5000);
      sortBy = 'rating';
    });
    fetchRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              searchQuery: searchQuery,
              onSearch: (v) {
                setState(() => searchQuery = v);
                fetchRestaurants();
              },
              onFilterTap: () => setState(() => showFilters = true),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'sipzy'),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurants.isEmpty) {
      return _EmptyState(onClear: clearFilters, hasFilters: _hasActiveFilters);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (featuredRestaurants.isNotEmpty &&
            !_hasActiveFilters &&
            searchQuery.isEmpty)
          _HorizontalSection('Featured Spots', featuredRestaurants),
        if (trendingRestaurants.isNotEmpty &&
            !_hasActiveFilters &&
            searchQuery.isEmpty)
          _HorizontalSection('Trending Restaurants', trendingRestaurants),
        _GridSection(
          title: searchQuery.isNotEmpty || _hasActiveFilters
              ? 'Results (${restaurants.length})'
              : 'Nearby Restaurants',
          restaurants: restaurants,
          bookmarkedIds: bookmarkedIds,
          onShare: (item) => setState(() => shareItem = item),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;

  const _Header({
    required this.searchQuery,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search restaurants...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  final bool hasFilters;

  const _EmptyState({required this.onClear, required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No restaurants found'),
          if (hasFilters)
            TextButton(onPressed: onClear, child: const Text('Clear Filters')),
        ],
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  final String title;
  final List restaurants;

  const _HorizontalSection(this.title, this.restaurants);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Column(
                    children: [
                      Image.network(
                        restaurant['image'],
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          restaurant['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GridSection extends StatelessWidget {
  final String title;
  final List restaurants;
  final List<int> bookmarkedIds;
  final void Function(Map<String, dynamic>) onShare;

  const _GridSection({
    required this.title,
    required this.restaurants,
    required this.bookmarkedIds,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = Map<String, dynamic>.from(
              restaurants[index] as Map,
            );

            final isBookmarked = bookmarkedIds.contains(restaurant['id']);

            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        restaurant['image'],
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          restaurant['area'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
