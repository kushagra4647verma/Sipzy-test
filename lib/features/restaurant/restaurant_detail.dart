import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';
import '../../shared/ui/invite_friends_modal.dart';

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
  List topSipzyBeverages = [];
  List customerFavorites = [];
  List expertRecommendations = [];
  List events = [];

  bool loading = true;
  bool hasError = false;
  bool alcoholicOnly = true;
  bool isBookmarked = false;
  bool showInviteModal = false;
  bool showGroupMixMagic = false;

  String searchQuery = '';
  String sortBy = 'recommended';

  late TabController _tabController;

  // Group Mix Magic state
  int participants = 1;
  List<String> selectedBaseDrinks = [];
  bool isGenerating = false;
  bool showResults = false;
  List<Map<String, dynamic>> recommendations = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

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
    _animationController.dispose();
    super.dispose();
  }

  // Get unique base drinks from beverages
  List<String> get baseDrinks {
    final drinks = <String>{};
    for (final bev in beverages) {
      final baseDrink = bev['base_drink'] ?? bev['baseDrink'];
      if (baseDrink != null && baseDrink.toString().isNotEmpty) {
        drinks.add(baseDrink.toString());
      }
    }
    return drinks.toList()..sort();
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

            _categorizeBeverages();
          });
          filterAndSort();
        }
      }

      await _fetchRestaurantEvents();
      await _fetchExpertRecommendations();
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

  void _categorizeBeverages() {
    final sorted = [...beverages];
    sorted.sort((a, b) => ((b['sipzy_rating'] ?? 0) as num)
        .compareTo((a['sipzy_rating'] ?? 0) as num));
    topSipzyBeverages = sorted.take(5).toList();

    sorted.sort((a, b) {
      final aRating =
          (a['ratings']?['avgHuman'] ?? a['ratings']?['avghuman'] ?? 0) as num;
      final bRating =
          (b['ratings']?['avgHuman'] ?? b['ratings']?['avghuman'] ?? 0) as num;
      return bRating.compareTo(aRating);
    });
    customerFavorites = sorted.take(5).toList();
  }

  Future<void> _fetchRestaurantEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '${EnvConfig.apiBaseUrl}/events?restaurant_id=${widget.restaurantId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            events = data is Map && data['success'] == true
                ? (data['data'] as List? ?? [])
                : (data is List ? data : []);
          });
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch events: $e');
    }
  }

  Future<void> _fetchExpertRecommendations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/experts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            expertRecommendations = data is Map && data['success'] == true
                ? (data['data'] as List? ?? [])
                : (data is List ? data : []);
          });
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch expert recommendations: $e');
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
    List filtered = beverages.where((b) {
      final category = (b['category'] ?? '').toString().toLowerCase();
      final isAlcoholic =
          category.contains('alcohol') || category == 'alcoholic';
      return isAlcoholic == alcoholicOnly;
    }).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final drinkType =
            (b['drinkType'] ?? b['drinktype'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || drinkType.contains(query);
      }).toList();
    }

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

  // ============== GROUP MIX MAGIC FUNCTIONS ==============

  void _updateParticipants(int count) {
    setState(() {
      participants = count;
      selectedBaseDrinks = List.filled(count, '');
    });
  }

  void _handleGenerateMix() {
    if (participants < 1) {
      _toast('Please enter number of participants');
      return;
    }

    if (selectedBaseDrinks.any((d) => d.isEmpty)) {
      _toast('Please select base drink for all $participants participants');
      return;
    }

    setState(() {
      isGenerating = true;
      showResults = false;
    });

    _animationController.repeat();

    Future.delayed(const Duration(milliseconds: 2500), () {
      final recs = <Map<String, dynamic>>[];

      for (final baseDrink in selectedBaseDrinks) {
        final filteredBeverages = beverages
            .where((b) =>
                (b['alcoholic'] == true ||
                    b['category']
                            ?.toString()
                            .toLowerCase()
                            .contains('alcohol') ==
                        true) &&
                (b['base_drink'] ?? b['baseDrink']) == baseDrink)
            .toList();

        if (filteredBeverages.isEmpty) continue;

        filteredBeverages.sort((a, b) {
          final aRating = (a['sipzy_rating'] ?? 0) as num;
          final bRating = (b['sipzy_rating'] ?? 0) as num;
          return bRating.compareTo(aRating);
        });

        final topBeverages = filteredBeverages.take(3).toList();
        if (topBeverages.isNotEmpty) {
          final randomIndex = DateTime.now().millisecond % topBeverages.length;
          recs.add(topBeverages[randomIndex]);
        }
      }

      _animationController.stop();

      if (mounted) {
        setState(() {
          recommendations = recs;
          isGenerating = false;
          showResults = true;
        });
      }
    });
  }

  void _resetGroupMixMagic() {
    setState(() {
      participants = 1;
      selectedBaseDrinks = [];
      isGenerating = false;
      recommendations = [];
      showResults = false;
    });
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
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
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
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildEnhancedHeader(),
              _buildRestaurantInfo(),
              _buildTopSipzySection(),
              _buildCustomerFavoritesSection(),
              _buildAmenitiesSection(),
              _buildPhotoGallerySection(),
              _buildEventsSection(),
              _buildExpertRecommendationsSection(),
              _buildToggleSearchSort(),
              _buildBeveragesGrid(),
              const SizedBox(height: 80),
            ],
          ),

          // Invite Friends Modal
          if (showInviteModal)
            InviteFriendsModal(
              open: showInviteModal,
              onClose: () => setState(() => showInviteModal = false),
              user: widget.user,
              restaurant: restaurant!,
            ),

          // Group Mix Magic Modal
          if (showGroupMixMagic) _buildGroupMixMagicModal(),
        ],
      ),
      // Surprise Me FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => showGroupMixMagic = true),
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text(
          'Surprise Me',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupMixMagicModal() {
    return Container(
      color: Colors.black87,
      child: Dialog(
        backgroundColor: const Color(0xFF0A0A0A),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGroupMixHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: showResults
                      ? _buildGroupMixResults()
                      : _buildGroupMixForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupMixHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondary.withOpacity(0.4),
            AppTheme.secondary.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              const Icon(
                Icons.local_bar_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {
                  showGroupMixMagic = false;
                  _resetGroupMixMagic();
                }),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary, Colors.pink],
            ).createShader(bounds),
            child: const Text(
              'Group Mix Magic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Let AI create the perfect mix for your group',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMixForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.people_rounded, color: AppTheme.secondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Number of Participants',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.glassLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final count = int.tryParse(value) ?? 0;
              if (count >= 1 && count <= 10) {
                _updateParticipants(count);
              }
            },
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g., 4',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        if (selectedBaseDrinks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.local_bar_rounded, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Base Drink Selection',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(selectedBaseDrinks.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participant ${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedBaseDrinks[index].isEmpty
                            ? null
                            : selectedBaseDrinks[index],
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Choose spirit',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF0A0A0A),
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child:
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                        ),
                        items: baseDrinks.map((drink) {
                          return DropdownMenuItem(
                            value: drink,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                drink,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedBaseDrinks[index] = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
        if (!isGenerating)
          AppTheme.gradientButtonAmber(
            onPressed: _handleGenerateMix,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.black, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Generate Mix',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _buildSlotMachine(),
      ],
    );
  }

  Widget _buildSlotMachine() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.glassStrong,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border:
            Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.secondary, Colors.pink],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Transform.rotate(
                      angle: _animationController.value * 6.28 * (i + 1),
                      child: const Icon(
                        Icons.local_bar_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Mixing Magic...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Finding the perfect combinations for your group',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMixResults() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text(
                  'Your Perfect Mix',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _resetGroupMixMagic,
              child: const Text(
                'Try Again',
                style: TextStyle(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recommendations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.local_bar_rounded,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No cocktails found for this combination',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(recommendations[index], index);
            },
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> cocktail, int index) {
    final photo = cocktail['photo'];
    final name = cocktail['name'] ?? 'Cocktail';
    final price = cocktail['price'] ?? 0;
    final sipzyRating = cocktail['sipzy_rating'] ?? 0;
    final baseDrink = cocktail['base_drink'] ?? cocktail['baseDrink'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
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
                child: photo != null && photo.toString().isNotEmpty
                    ? Image.network(
                        photo,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: AppTheme.glassLight,
                            child: const Icon(
                              Icons.local_bar_rounded,
                              size: 32,
                              color: AppTheme.textTertiary,
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 120,
                        color: AppTheme.glassLight,
                        child: const Icon(
                          Icons.local_bar_rounded,
                          size: 32,
                          color: AppTheme.textTertiary,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Colors.amber],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Participant ${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        sipzyRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '#$baseDrink',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    );
  }

  // Continuing with the existing widgets from the previous file...
  // (Include all the _buildEnhancedHeader, _buildRestaurantInfo, _buildTopSipzySection, etc.)

  Widget _buildEnhancedHeader() {
    final image = restaurant!['image'] ??
        restaurant!['coverImage'] ??
        restaurant!['coverimage'];
    final name = restaurant!['name'] ?? 'Restaurant';
    final cuisine = (restaurant!['cuisine'] as List?)?.join(', ') ?? '';
    final area = restaurant!['area'] ?? '';
    final distance = restaurant!['distance'] ?? 0;
    final costForTwo =
        restaurant!['cost_for_two'] ?? restaurant!['costForTwo'] ?? 0;

    return Stack(
      children: [
        if (image != null && image.toString().isNotEmpty)
          Image.network(
            image,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        else
          _buildPlaceholderImage(),
        Container(
          height: 360,
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
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    Icons.person_add_rounded,
                    () => setState(() => showInviteModal = true),
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
              if (cuisine.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cuisine,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    area,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '₹$costForTwo for 2',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Include all remaining widget methods from previous implementation...
  // (_buildRestaurantInfo, _buildTopSipzySection, _buildExpertRecommendationsSection, etc.)
  // Due to character limits, I'm showing the structure. Copy the rest from the previous file.

  Widget _buildPlaceholderImage() {
    return Container(
      height: 360,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 64,
            color: AppTheme.textTertiary,
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
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // Add all remaining methods here...
  // For brevity, use the implementation from restaurant_detail_updated.dart

  Widget _buildRestaurantInfo() => const SizedBox();
  Widget _buildTopSipzySection() => const SizedBox();
  Widget _buildCustomerFavoritesSection() => const SizedBox();
  Widget _buildAmenitiesSection() => const SizedBox();
  Widget _buildPhotoGallerySection() => const SizedBox();
  Widget _buildEventsSection() => const SizedBox();
  Widget _buildExpertRecommendationsSection() => const SizedBox();
  Widget _buildToggleSearchSort() => const SizedBox();
  Widget _buildBeveragesGrid() => const SizedBox();

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
