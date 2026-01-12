import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';

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

class _RestaurantDetailState extends State<RestaurantDetail>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? restaurant;
  List beverages = [];
  List filteredBeverages = [];

  bool loading = true;
  bool hasError = false;
  bool alcoholicOnly = true;
  bool isBookmarked = false;

  String searchQuery = '';
  String sortBy = 'recommended';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Reset filters
    setState(() {
      alcoholicOnly = true;
      searchQuery = '';
      sortBy = 'recommended';
    });

    fetchRestaurant();
    checkBookmark();
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
    }

    if (user?.id != null) {
      headers['x-user-id'] = user!.id;
    } else if (widget.user['id'] != null) {
      headers['x-user-id'] = widget.user['id'].toString();
    }

    return headers;
  }

  Future<void> fetchRestaurant() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final headers = await _getHeaders();

      // Fetch restaurant details
      final restaurantRes = await http
          .get(
            Uri.parse(
                '${EnvConfig.apiBaseUrl}/restaurants/${widget.restaurantId}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (restaurantRes.statusCode == 200) {
        final data = jsonDecode(restaurantRes.body);
        if (mounted) {
          setState(() {
            restaurant = data is Map &&
                    data.containsKey('success') &&
                    data['success'] == true
                ? data['data']
                : data;
          });
        }
      }

      // Fetch beverages
      final beveragesRes = await http
          .get(
            Uri.parse(
                '${EnvConfig.apiBaseUrl}/restaurants/${widget.restaurantId}/beverages'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (beveragesRes.statusCode == 200) {
        final data = jsonDecode(beveragesRes.body);
        if (mounted) {
          setState(() {
            beverages = data is Map &&
                    data.containsKey('success') &&
                    data['success'] == true
                ? (data['data'] as List? ?? [])
                : (data is List ? data : []);
          });
          filterAndSort();
        }
      }
    } catch (e) {
      print('❌ Fetch restaurant error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load restaurant', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> checkBookmark() async {
    try {
      final headers = await _getHeaders();
      final userId = _supabase.auth.currentUser?.id ?? widget.user['id'];

      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/users/$userId/bookmarks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookmarks = data is Map && data.containsKey('data')
            ? (data['data'] as List? ?? [])
            : (data is List ? data : []);

        if (mounted) {
          setState(() {
            isBookmarked = bookmarks.any((b) =>
                b['restaurantid']?.toString() == widget.restaurantId ||
                b['id']?.toString() == widget.restaurantId);
          });
        }
      }
    } catch (e) {
      print('⚠️ Failed to check bookmark: $e');
    }
  }

  Future<void> toggleBookmark() async {
    try {
      final headers = await _getHeaders();
      final userId = _supabase.auth.currentUser?.id ?? widget.user['id'];

      final response = await http.post(
        Uri.parse(
            '${EnvConfig.apiBaseUrl}/users/$userId/bookmarks/${widget.restaurantId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() => isBookmarked = !isBookmarked);
        _toast(isBookmarked ? 'Bookmarked!' : 'Bookmark removed');
        checkBookmark();
      }
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      _toast('Failed to update bookmark', isError: true);
    }
  }

  void filterAndSort() {
    // Filter by alcoholic/non-alcoholic
    List filtered = beverages.where((b) {
      final category = (b['category'] ?? '').toString().toLowerCase();
      final isAlcoholic =
          category.contains('alcohol') || category == 'alcoholic';
      return isAlcoholic == alcoholicOnly;
    }).toList();

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final drinkType =
            (b['drinkType'] ?? b['drinktype'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || drinkType.contains(query);
      }).toList();
    }

    // Sort
    if (sortBy == 'price_low') {
      filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
    } else if (sortBy == 'price_high') {
      filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
    }

    setState(() => filteredBeverages = filtered);
  }

  void callRestaurant() async {
    final phone = restaurant?['phone'];
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void openMaps() async {
    final lat = restaurant?['latitude'] ?? restaurant?['lat'];
    final lon = restaurant?['longitude'] ?? restaurant?['lon'];

    if (lat != null && lon != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (hasError || restaurant == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
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
                    'Failed to load restaurant',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  AppTheme.gradientButtonAmber(
                    onPressed: fetchRestaurant,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildToggleSearchSort(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBeveragesTab(),
                _buildFoodMenuTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final image = restaurant!['image'] ??
        restaurant!['coverImage'] ??
        restaurant!['coverimage'];
    final name = restaurant!['name'] ?? 'Restaurant';
    final area = restaurant!['area'] ?? '';

    return Stack(
      children: [
        // Image
        if (image != null && image.toString().isNotEmpty)
          Image.network(
            image,
            height: 320,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        else
          _buildPlaceholderImage(),

        // Gradient
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

        // Top action buttons
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                Icons.arrow_back_rounded,
                () => Navigator.pop(context),
              ),
              Row(
                children: [
                  _buildCircleButton(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    toggleBookmark,
                  ),
                  if (restaurant!['phone'] != null) ...[
                    const SizedBox(width: 8),
                    _buildCircleButton(Icons.call_rounded, callRestaurant),
                  ],
                  const SizedBox(width: 8),
                  _buildCircleButton(Icons.map_rounded, openMaps),
                ],
              ),
            ],
          ),
        ),

        // Restaurant info
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                area,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 320,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildToggleSearchSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Veg/Non-Veg style toggle + Search + Sort
          Row(
            children: [
              // Toggle buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.glassLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      icon: Icons.local_bar_rounded,
                      isSelected: alcoholicOnly,
                      onTap: () {
                        setState(() => alcoholicOnly = true);
                        filterAndSort();
                      },
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    _buildToggleButton(
                      icon: Icons.coffee_rounded,
                      isSelected: !alcoholicOnly,
                      onTap: () {
                        setState(() => alcoholicOnly = false);
                        filterAndSort();
                      },
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Search
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    onChanged: (v) {
                      searchQuery = v;
                      filterAndSort();
                    },
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search beverages...',
                      hintStyle:
                          TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.textSecondary, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sort button
              InkWell(
                onTap: () => _showSortSheet(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: AppTheme.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          // Tab bar
          const SizedBox(height: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.glassLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Detailed Beverage Menu'),
                Tab(text: 'Food Menu Photo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : AppTheme.textTertiary,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.black : AppTheme.textTertiary,
        ),
      ),
    );
  }

  Widget _buildBeveragesTab() {
    if (filteredBeverages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No beverages found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'Try different search terms'
                    : 'No ${alcoholicOnly ? "alcoholic" : "non-alcoholic"} beverages available',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: 24),
                AppTheme.gradientButtonAmber(
                  onPressed: () {
                    setState(() => searchQuery = '');
                    filterAndSort();
                  },
                  child: const Text('Clear Search'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredBeverages.length,
      itemBuilder: (context, index) {
        final bev = filteredBeverages[index];
        return _buildBeverageCard(bev);
      },
    );
  }

  Widget _buildBeverageCard(Map bev) {
    final photo = bev['photo'];
    final name = bev['name'] ?? 'Beverage';
    final drinkType =
        bev['drinkType'] ?? bev['drinktype'] ?? bev['category'] ?? '';
    final price = bev['price'] ?? 0;
    final ratings = bev['ratings'] as Map<String, dynamic>? ?? {};
    final avgHuman = ratings['avgHuman'] ?? ratings['avghuman'] ?? 0;
    final countHuman = ratings['countHuman'] ?? ratings['counthuman'] ?? 0;
    final avgExpert = ratings['avgExpert'] ?? ratings['avgexpert'] ?? 0;

    return InkWell(
      onTap: () => context.push('/beverage/${bev['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
              child: photo != null && photo.toString().isNotEmpty
                  ? Image.network(
                      photo,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildBeveragePlaceholder();
                      },
                    )
                  : _buildBeveragePlaceholder(),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    drinkType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ratings
                  Column(
                    children: [
                      _buildSmallRating(
                          'Customer', avgHuman, countHuman, AppTheme.secondary),
                      const SizedBox(height: 4),
                      _buildSmallRating(
                          'Expert', avgExpert, null, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildBeveragePlaceholder() {
    return Container(
      height: 120,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_rounded,
            size: 32,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallRating(
      String label, dynamic value, dynamic count, Color color) {
    final ratingValue = (value is num ? value.toDouble() : 0.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10,
          ),
        ),
        Row(
          children: [
            Icon(Icons.star_rounded, color: color, size: 12),
            const SizedBox(width: 2),
            Text(
              ratingValue.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count != null)
              Text(
                ' ($count)',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodMenuTab() {
    final photos = restaurant!['photos'] as List? ?? [];

    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No menu photos available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for food menu photos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Image.network(
            photos[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.glassLight,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: AppTheme.textTertiary,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Recommended', 'recommended', '⭐'),
              _buildSortOption('Price: Low to High', 'price_low', '↑'),
              _buildSortOption('Price: High to Low', 'price_high', '↓'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, String icon) {
    final isSelected = sortBy == value;

    return InkWell(
      onTap: () {
        setState(() => sortBy = value);
        filterAndSort();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.glassStrong : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
