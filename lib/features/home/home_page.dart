// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../shared/navigation/bottom_nav.dart';
import '../../core/theme/app_theme.dart';
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
  bool hasError = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      await Future.wait([fetchRestaurants(), fetchBookmarks()]);
    } catch (e) {
      setState(() => hasError = true);
    }
  }

  Future<void> fetchRestaurants() async {
    try {
      final userId = widget.user['id'] ?? widget.user['userId'];
      final uri = searchQuery.isNotEmpty
          ? Uri.parse('${ApiService.restaurantService}?search=$searchQuery')
          : Uri.parse(ApiService.restaurantService);

      final response = await http.get(
        uri,
        headers: ApiService.getUserHeaders(userId.toString()),
      );
      print(ApiService.getUserHeaders(userId.toString()));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          restaurants =
              data['success'] == true ? (data['data'] as List) : (data as List);
          hasError = false;
        });
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      setState(() => hasError = true);
      _toast('Failed to load restaurants', isError: true);
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
      _toast('Failed to update bookmark', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
      return _buildLoadingSkeleton();
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (restaurants.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primary,
      backgroundColor: AppTheme.card,
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

          return _RestaurantCard(
            restaurant: restaurant,
            isBookmarked: isBookmarked,
            onTap: () => context.push('/restaurant/${restaurant['id']}'),
            onBookmark: () => toggleBookmark(restaurant['id'].toString()),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.card,
          highlightColor: AppTheme.glassLight,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
        );
      },
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
              'Unable to load restaurants',
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
              onPressed: _loadAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No restaurants found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            AppTheme.gradientButtonAmber(
              onPressed: () {
                setState(() => searchQuery = '');
                fetchRestaurants();
              },
              child: const Text('Clear Search'),
            ),
          ],
        ],
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_bar_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                'SipZy',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onSearch,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search restaurants...',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.glassLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map restaurant;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _RestaurantCard({
    required this.restaurant,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: Image.network(
                    restaurant['image'] ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: AppTheme.glassLight,
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 40,
                          color: AppTheme.textTertiary,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onBookmark,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: AppTheme.primary,
                        size: 20,
                      ),
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant['area'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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
}
