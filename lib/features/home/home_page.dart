import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/restaurant_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/ui/share_modal.dart';
import '../../shared/utils/keyboard_dismisser.dart';
import '../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  final _restaurantService = RestaurantService();
  final _userService = UserService();

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

    setState(() {
      searchQuery = '';
      sortBy = 'rating';
    });

    _initializeLocation();
    _loadAll();
  }

  Future<void> _initializeLocation() async {
    final locationService = LocationService();

    // Request location permission
    final hasPermission = await locationService.requestLocationPermission();

    if (hasPermission) {
      final position = await locationService.getCurrentLocation();

      if (mounted && position != null && locationService.currentCity != null) {
        setState(() {
          selectedCity = locationService.currentCity!;
        });
      }
    }
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

  Future<void> fetchRestaurants() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      // ✅ Get current location
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      // ✅ Use detected city or selected city
      final cityToUse = locationService.currentCity ?? selectedCity;

      setState(() {
        if (locationService.currentCity != null) {
          selectedCity = locationService.currentCity!;
        }
      });

      // ✅ Fetch restaurants with location
      final fetchedRestaurants = await _restaurantService.getRestaurants(
        city: cityToUse,
        lat: position?.latitude,
        lon: position?.longitude,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        cuisine: selectedCuisines.isNotEmpty ? selectedCuisines.first : null,
        minRating: minRating > 0 ? minRating : null,
        maxDistance: maxDistance < 10 ? maxDistance : null,
        sortBy: sortBy,
      );

      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants;
          hasError = false;
        });

        // Fetch featured and trending only if no search/filters
        if (searchQuery.isEmpty && selectedCuisines.isEmpty && minRating == 0) {
          await _fetchFeaturedAndTrending(
            city: cityToUse,
            lat: position?.latitude,
            lon: position?.longitude,
          );
        } else {
          setState(() {
            featuredRestaurants = [];
            trendingRestaurants = [];
          });
        }
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

  Future<void> _fetchFeaturedAndTrending({
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      final results = await Future.wait([
        _restaurantService.getFeaturedRestaurants(
          lat: lat,
          lon: lon,
        ),
        if (city != null && city.isNotEmpty)
          _restaurantService.getTrendingRestaurants(city: city)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          featuredRestaurants = results[0];
          trendingRestaurants = results[1];
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch featured/trending: $e');
    }
  }

  Future<void> fetchBookmarks() async {
    try {
      final bookmarksList = await _userService.getBookmarks();

      if (mounted) {
        setState(() {
          bookmarkedIds = bookmarksList
              .map((e) {
                final id = e['restaurantId'] ?? e['restaurantid'] ?? e['id'];
                if (id == null) return 0;
                if (id is int) return id;
                if (id is String) return int.tryParse(id) ?? 0;
                if (id is num) return id.toInt();
                return 0;
              })
              .where((id) => id != 0)
              .toList();
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    try {
      final success = await _userService.toggleBookmark(restaurantId);

      if (success) {
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

  String _getSortLabel() {
    switch (sortBy) {
      case 'rating':
        return 'Highest Rating';
      case 'distance':
        return 'Nearest First';
      case 'cost_low':
        return 'Cost: Low to High';
      case 'cost_high':
        return 'Cost: High to Low';
      default:
        return 'Highest Rating';
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
    return KeyboardDismisser(
      child: Scaffold(
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
      ),
    );
  }

  void _showCitySelector() {
    final locationService = LocationService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Current Location Option
            ListTile(
              leading: const Icon(Icons.my_location, color: AppTheme.primary),
              title: const Text(
                'Use Current Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                final position = await locationService.getCurrentLocation(
                    forceRefresh: true);

                if (mounted) {
                  if (position != null && locationService.currentCity != null) {
                    setState(() {
                      selectedCity = locationService.currentCity!;
                    });
                    fetchRestaurants();
                    _toast(
                        'Location updated to ${locationService.currentCity}');
                  } else {
                    _toast('Could not detect your city', isError: true);
                  }
                }
              },
            ),
            const Divider(),

            // City List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: cities.map((city) {
                  final isSelected = city == selectedCity;

                  return ListTile(
                    title: Text(
                      city,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedCity = city;
                        locationService.setCity(city);
                      });

                      Navigator.pop(context);
                      fetchRestaurants();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  final cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
  ];
  String selectedCity = 'Bangalore';

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
          // ✅ NEW: Top Row with Location and Expert Corner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Selector (left)
              InkWell(
                onTap: _showCitySelector,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedCity,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // ✅ Expert Corner Button (right)
              InkWell(
                onTap: () => context.push('/expert-corner'),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondary, AppTheme.secondaryLight],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Expert Corner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.glassLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              onChanged: (v) {
                setState(() => searchQuery = v);
                // Debounce search to avoid too many API calls
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (searchQuery == v) {
                    fetchRestaurants();
                  }
                });
              },
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search restaurants, cuisines, areas...',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: Icon(
                  Icons.mic_rounded,
                  color: AppTheme.primary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter & Sort Buttons Row
          Row(
            children: [
              // Filters Button
              Expanded(
                child: InkWell(
                  onTap: _showFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filters',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
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
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort Dropdown Button
              Expanded(
                child: InkWell(
                  onTap: _showSort,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 18,
                          color: AppTheme.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSortLabel(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ],
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
          // ❌ REMOVE Expert Corner card from here

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

    // ✅ FIXED: Use correct field names from API
    final image = restaurant['logoImage'] ??
        restaurant['coverImage'] ??
        restaurant['image'];

    final name = restaurant['name'] ?? 'Restaurant';
    final area = restaurant['area'] ?? '';
    final distance = (restaurant['distance'] ?? 0).toDouble();

    // ✅ FIXED: API returns 'cuisineTags' not 'cuisine'
    final cuisines = (restaurant['cuisineTags'] as List?)?.take(2).toList() ??
        (restaurant['cuisine'] as List?)?.take(2).toList() ??
        [];

    final topDrink = restaurant['top_drink'] ?? '';

    // ✅ FIXED: Calculate cost_for_two from priceRange if not available
    final costForTwo = restaurant['cost_for_two'] ??
        restaurant['costForTwo'] ??
        (restaurant['priceRange'] ?? 0) * 500;

    // ✅ FIXED: sipzy_rating might not be in list response
    final rating = restaurant['sipzy_rating'] ?? restaurant['rating'] ?? 4.0;

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
            // ================= IMAGE + ACTIONS =================
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
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),

                // Gradient overlay
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
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          toggleBookmark(restaurantId.toString());
                        },
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ShareModal(
                              onClose: () => Navigator.pop(context),
                              item: {
                                'title': name,
                                'description': 'Check out this restaurant!',
                                'url':
                                    'https://sipzy.co.in/restaurant/$restaurantId',
                              },
                            ),
                          );
                        },
                        child: Container(
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
                      ),
                    ],
                  ),
                ),

                // Name + Location
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
                          Expanded(
                            child: Text(
                              '$area • ${distance.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ================= DETAILS =================
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cuisines
                  if (cuisines.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cuisines
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c.toString(),
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  // Top Drink
                  if (topDrink.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_bar,
                          color: AppTheme.secondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            topDrink,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Rating & Cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                              rating.toStringAsFixed(1),
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
                        '₹$costForTwo for 2',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
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
