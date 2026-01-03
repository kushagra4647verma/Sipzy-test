import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../shared/navigation/bottom_nav.dart';
import '../../shared/ui/share_modal.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const API = String.fromEnvironment('API_URL');

  // data
  List restaurants = [];
  List featuredRestaurants = [];
  List trendingRestaurants = [];
  List bookmarkedIds = [];

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

    final uri = Uri.parse('$API/restaurants').replace(queryParameters: query);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      restaurants = jsonDecode(res.body);
    }

    if (searchQuery.isEmpty && !_hasActiveFilters) {
      featuredRestaurants = await _fetchList('$API/restaurants/featured');
      trendingRestaurants = await _fetchList('$API/restaurants/trending');
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
      Uri.parse('$API/bookmarks/${widget.user['id']}'),
    );
    if (res.statusCode == 200) {
      bookmarkedIds = List.from(jsonDecode(res.body).map((e) => e['id']));
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
