// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

import '../../shared/navigation/bottom_nav.dart';
import '../../core/theme/colors.dart';
import '../../services/api_service.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List restaurants = [];
  List<int> bookmarkedIds = [];

  bool loading = true;
  String searchQuery = '';

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

    try {
      final userId = widget.user['id'] ?? widget.user['userId'];
      final uri = searchQuery.isNotEmpty
          ? Uri.parse('${ApiService.restaurantService}?search=$searchQuery')
          : Uri.parse(ApiService.restaurantService);

      final response = await http.get(
        uri,
        headers: ApiService.getUserHeaders(userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          restaurants =
              data['success'] == true ? (data['data'] as List) : (data as List);
        });
      }
    } catch (e) {
      _toast('Failed to load restaurants: ${e.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchBookmarks() async {
    try {
      final userId = widget.user['id'] ?? widget.user['userId'];
      final response = await http.get(
        Uri.parse('${ApiService.userService}/me/bookmarks'),
        headers: ApiService.getUserHeaders(userId.toString()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookmarks =
            data['success'] == true ? (data['data'] as List) : (data as List);

        setState(() {
          bookmarkedIds =
              bookmarks.map((e) => (e['id'] as num).toInt()).toList();
        });
      }
    } catch (e) {
      print('Failed to fetch bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    try {
      final userId = widget.user['id'] ?? widget.user['userId'];
      final response = await http.post(
        Uri.parse('${ApiService.userService}/bookmarks/$restaurantId'),
        headers: ApiService.getUserHeaders(userId.toString()),
      );

      if (response.statusCode == 200) {
        await fetchBookmarks();
        _toast('Bookmark updated');
      }
    } catch (e) {
      _toast('Failed to update bookmark');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No restaurants found',
              style: TextStyle(color: Colors.white),
            ),
            if (searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() => searchQuery = '');
                  fetchRestaurants();
                },
                child: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          final isBookmarked = bookmarkedIds.contains(restaurant['id']);

          return GestureDetector(
            onTap: () => context.push('/restaurant/${restaurant['id']}'),
            child: Card(
              color: AppColors.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          restaurant['image'] ?? '',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120,
                              color: AppColors.muted,
                              child: const Icon(
                                Icons.restaurant,
                                size: 40,
                                color: Colors.white38,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppColors.primary,
                          ),
                          onPressed: () => toggleBookmark(
                            restaurant['id'].toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant['name'] ?? 'Restaurant',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['area'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.searchQuery,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_bar, color: AppColors.primary, size: 28),
              SizedBox(width: 8),
              Text(
                'SipZy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'Search restaurants...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
