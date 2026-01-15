import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _supabase = Supabase.instance.client;

  List restaurants = [];
  List featuredRestaurants = [];
  List trendingRestaurants = [];
  List<int> bookmarkedIds = [];

  bool loading = true;
  bool hasError = false;
  String searchQuery = '';

  List<String> selectedCuisines = [];
  double minRating = 0;
  double maxDistance = 10;
  double minCost = 0;
  double maxCost = 5000;

  String sortBy = 'rating';
  final baseDrinks = [
    'Whisky',
    'Rum',
    'Vodka',
    'Gin',
    'Beer',
    'Wine',
    'Water',
    'Soda',
    'Milk',
    'Juice'
  ];

  Set<String> selectedBaseDrinks = {};
  final restaurantTypes = [
    'Fine Dining',
    'Casual',
    'Romantic',
    'Gastropub',
    'Brewery'
  ];

  Set<String> selectedRestaurantTypes = {};

  final cuisines = [
    'Indian',
    'Continental',
    'Asian',
    'Mediterranean',
    'Italian',
    'Chinese'
  ];

  @override
  void initState() {
    super.initState();

    // Reset filters on load
    searchQuery = '';
    selectedCuisines = [];
    minRating = 0;
    maxDistance = 10;
    sortBy = 'rating';

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
      print('Error loading data: $e');
      setState(() => hasError = true);
    }
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
    }

    return headers;
  }

  Future<void> fetchRestaurants() async {
    try {
      final headers = await _getHeaders();

      // Build query params
      final params = <String, String>{};
      if (searchQuery.isNotEmpty) params['search'] = searchQuery;
      if (selectedCuisines.isNotEmpty) {
        params['cuisine'] = selectedCuisines.first;
      }
      if (minRating > 0) params['min_rating'] = minRating.toString();
      if (maxDistance < 10) params['max_distance'] = maxDistance.toString();
      params['sort_by'] = sortBy;

      final uri = Uri.parse(ApiService.restaurantService)
          .replace(queryParameters: params);

      print('📡 Fetching restaurants from: $uri');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            restaurants = data['success'] == true
                ? (data['data'] as List? ?? [])
                : (data is List ? data : []);
            hasError = false;
          });
        }

        // Fetch featured and trending only if no search
        if (searchQuery.isEmpty && selectedCuisines.isEmpty && minRating == 0) {
          await _fetchFeaturedAndTrending(headers);
        } else {
          if (mounted) {
            setState(() {
              featuredRestaurants = [];
              trendingRestaurants = [];
            });
          }
        }
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed - session may have expired');
        if (mounted) {
          _toast('Session expired. Please login again.', isError: true);
          context.go('/auth');
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch restaurants error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load restaurants', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _fetchFeaturedAndTrending(Map<String, String> headers) async {
    try {
      if (restaurants.isNotEmpty) {
        if (mounted) {
          setState(() {
            featuredRestaurants = restaurants.take(5).toList();
            trendingRestaurants = restaurants.skip(5).take(5).toList();
          });
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch featured/trending: $e');
    }
  }

  Future<void> fetchBookmarks() async {
    try {
      final headers = await _getHeaders();
      final userId = _supabase.auth.currentUser?.id ?? widget.user['id'];

      final response = await http.get(
        Uri.parse('${ApiService.userService}/$userId/bookmarks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookmarks = data['success'] == true
            ? (data['data'] as List? ?? [])
            : (data is List ? data : []);

        if (mounted) {
          setState(() {
            bookmarkedIds = bookmarks
                .map((e) =>
                    (e['restaurantId'] ?? e['restaurantid'] ?? e['id']) as num)
                .map((e) => e.toInt())
                .toList();
          });
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final userId = _supabase.auth.currentUser?.id ?? widget.user['id'];

      final response = await http.post(
        Uri.parse('${ApiService.userService}/$userId/bookmarks/$restaurantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await fetchBookmarks();
        if (mounted) {
          _toast('Bookmark updated');
        }
      }
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      if (mounted) {
        _toast('Failed to update bookmark', isError: true);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9, // ✅ FULL HEIGHT
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max, // ✅ IMPORTANT FIX
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // CUISINE
                      const Text(
                        'Cuisine',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cuisines.map((cuisine) {
                          final isSelected = selectedCuisines.contains(cuisine);
                          return _filterChip(
                            label: cuisine,
                            isSelected: isSelected,
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedCuisines.remove(cuisine);
                                } else {
                                  selectedCuisines.clear();
                                  selectedCuisines.add(cuisine);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // BASE DRINK
                      const Text(
                        'Base Drink',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: baseDrinks.map((drink) {
                          final isSelected = selectedBaseDrinks.contains(drink);
                          return _filterChip(
                            label: drink,
                            isSelected: isSelected,
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedBaseDrinks.remove(drink);
                                } else {
                                  selectedBaseDrinks.add(drink);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // RATING
                      Text(
                        'SipZy Rating: ${minRating.toStringAsFixed(1)}+ stars',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: AppTheme.primary,
                        inactiveColor: AppTheme.border,
                        onChanged: (value) {
                          setModalState(() => minRating = value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // DISTANCE
                      Text(
                        'Distance: Up to ${maxDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: maxDistance,
                        min: 0,
                        max: 10,
                        divisions: 20,
                        activeColor: AppTheme.primary,
                        inactiveColor: AppTheme.border,
                        onChanged: (value) {
                          setModalState(() => maxDistance = value);
                        },
                      ),

                      const SizedBox(height: 24),

                      // RESTAURANT TYPE
                      const Text(
                        'Restaurant Type',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: restaurantTypes.map((type) {
                          final isSelected =
                              selectedRestaurantTypes.contains(type);
                          return _filterChip(
                            label: type,
                            isSelected: isSelected,
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedRestaurantTypes.remove(type);
                                } else {
                                  selectedRestaurantTypes.add(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // COST FOR TWO
                      Text(
                        'Cost for Two: ₹${minCost.toInt()} - ₹${maxCost.toInt()}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: RangeValues(minCost, maxCost),
                        min: 0,
                        max: 5000,
                        divisions: 50,
                        activeColor: AppTheme.primary,
                        inactiveColor: AppTheme.border,
                        onChanged: (values) {
                          setModalState(() {
                            minCost = values.start;
                            maxCost = values.end;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // ACTION BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedCuisines.clear();
                                  selectedBaseDrinks.clear();
                                  selectedRestaurantTypes.clear();
                                  minRating = 0;
                                  maxDistance = 10;
                                  minCost = 0;
                                  maxCost = 5000;
                                });

                                setState(() {
                                  selectedCuisines.clear();
                                  selectedBaseDrinks.clear();
                                  selectedRestaurantTypes.clear();
                                  minRating = 0;
                                  maxDistance = 10;
                                  minCost = 0;
                                  maxCost = 5000;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(color: AppTheme.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusMd),
                                ),
                              ),
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTheme.gradientButtonAmber(
                              onPressed: () {
                                Navigator.pop(context);
                                fetchRestaurants();
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                )
              : null,
          color: isSelected ? null : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ compact sheet
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
              _buildSortOption('Highest Rating', 'rating'),
              _buildSortOption('Nearest First', 'distance'),
              _buildSortOption('Cost Low to High', 'cost_low'),
              _buildSortOption('Cost High to Low', 'cost_high'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = sortBy == value;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        setState(() => sortBy = value);
        Navigator.pop(context);
        fetchRestaurants();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary // ✅ gold highlight
              : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.black // ✅ black text on gold
                      : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check, // ✅ checkmark like screenshot
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
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
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'sipzy'),
    );
  }

  Widget _buildHeader() {
    final hasActiveFilters =
        selectedCuisines.isNotEmpty || minRating > 0 || maxDistance < 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location & User
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.local_bar_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SipZy',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'Welcome, ${widget.user['name'] ?? 'User'}!',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            onChanged: (v) {
              searchQuery = v;
              fetchRestaurants();
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search restaurants, cuisines, areas...',
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textSecondary),
              suffixIcon:
                  const Icon(Icons.mic_rounded, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.glassLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter & Sort buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list_rounded, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Filters'),
                      if (hasActiveFilters) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSort,
                  icon: const Icon(Icons.sort_rounded, size: 18),
                  label: const Text('Sort'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return _buildLoadingSkeleton();
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (restaurants.isEmpty &&
        featuredRestaurants.isEmpty &&
        trendingRestaurants.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primary,
      backgroundColor: AppTheme.card,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured Spots (only when not searching/filtering)
          if (searchQuery.isEmpty &&
              selectedCuisines.isEmpty &&
              minRating == 0 &&
              featuredRestaurants.isNotEmpty) ...[
            const Text(
              'Featured Spots',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: featuredRestaurants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 280,
                    child: _buildRestaurantCard(featuredRestaurants[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Trending Restaurants
          if (searchQuery.isEmpty &&
              selectedCuisines.isEmpty &&
              minRating == 0 &&
              trendingRestaurants.isNotEmpty) ...[
            const Text(
              'Trending Restaurants',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trendingRestaurants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 280,
                    child: _buildRestaurantCard(trendingRestaurants[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // All/Search Results
          Text(
            searchQuery.isNotEmpty ||
                    selectedCuisines.isNotEmpty ||
                    minRating > 0
                ? 'Results (${restaurants.length})'
                : 'Nearby Restaurants',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...restaurants.map((restaurant) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRestaurantCard(restaurant),
              )),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map restaurant) {
    final restaurantId = restaurant['id'];
    final isBookmarked = bookmarkedIds.contains(restaurantId);
    final image = restaurant['logoImage'] ??
        restaurant['coverImage'] ??
        restaurant['image'];
    final name = restaurant['name'] ?? 'Restaurant';
    final area = restaurant['area'] ?? '';
    final distance = restaurant['distance'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/restaurant/$restaurantId'),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: image != null && image.toString().isNotEmpty
                      ? Image.network(
                          image,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                // Bookmark & Share
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => toggleBookmark(restaurantId.toString()),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // Info at bottom
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            area,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant['sipzy_rating'] ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${restaurant['cost_for_two'] ?? 0} for 2',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.card,
          highlightColor: AppTheme.glassLight,
          child: Container(
            height: 280,
            margin: const EdgeInsets.only(bottom: 16),
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
            const Icon(
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
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
        ),
      ),
    );
  }
}
