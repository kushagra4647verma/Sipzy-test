// lib/features/restaurant/restaurant_detail.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../services/api_service.dart';

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
  Map<String, dynamic>? restaurant;
  List beverages = [];
  List filteredBeverages = [];

  bool loading = true;
  bool alcoholicOnly = true;
  bool isBookmarked = false;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchRestaurant();
    checkBookmark();
  }

  String get _userId => (widget.user['id'] ?? widget.user['userId']).toString();

  Future<void> fetchRestaurant() async {
    setState(() => loading = true);

    try {
      // Fetch restaurant details
      final restaurantRes = await http.get(
        Uri.parse('${ApiService.restaurantService}/${widget.restaurantId}'),
        headers: ApiService.getUserHeaders(_userId),
      );

      if (restaurantRes.statusCode == 200) {
        final data = jsonDecode(restaurantRes.body);
        setState(() {
          restaurant = data['success'] == true ? data['data'] : data;
        });
      }

      // Fetch restaurant beverages
      final beveragesRes = await http.get(
        Uri.parse(
          '${ApiService.restaurantService}/${widget.restaurantId}/beverages',
        ),
        headers: ApiService.getUserHeaders(_userId),
      );

      if (beveragesRes.statusCode == 200) {
        final data = jsonDecode(beveragesRes.body);
        setState(() {
          beverages = data['success'] == true ? data['data'] : data;
        });
        filterAndSort();
      }
    } catch (e) {
      _toast('Failed to load restaurant: ${e.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> checkBookmark() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.userService}/me/bookmarks'),
        headers: ApiService.getUserHeaders(_userId),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookmarks = data['success'] == true ? data['data'] : data;

        setState(() {
          isBookmarked = (bookmarks as List).any(
            (b) => b['id'].toString() == widget.restaurantId,
          );
        });
      }
    } catch (e) {
      print('Failed to check bookmark: $e');
    }
  }

  Future<void> toggleBookmark() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.userService}/bookmarks/${widget.restaurantId}'),
        headers: ApiService.getUserHeaders(_userId),
      );

      if (response.statusCode == 200) {
        setState(() => isBookmarked = !isBookmarked);
        _toast(isBookmarked ? 'Bookmarked!' : 'Bookmark removed');
      }
    } catch (e) {
      _toast('Failed to update bookmark');
    }
  }

  void filterAndSort() {
    List list = beverages
        .where((b) => (b['alcoholic'] ?? false) == alcoholicOnly)
        .toList();

    if (searchQuery.isNotEmpty) {
      list = list
          .where((b) =>
              (b['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (b['type'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
          .toList();
    }

    setState(() => filteredBeverages = list);
  }

  void callRestaurant() async {
    final phone = restaurant?['phone'];
    if (phone != null) {
      await launchUrl(Uri.parse('tel:$phone'));
    }
  }

  void openMaps() async {
    final lat = restaurant?['latitude'] ?? restaurant?['lat'];
    final lon = restaurant?['longitude'] ?? restaurant?['lon'];

    if (lat != null && lon != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );
      await launchUrl(url);
    }
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Restaurant not found'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _header(),
          _toggleSearchSort(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _menuSection(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Stack(
      children: [
        Image.network(
          restaurant!['image'] ?? '',
          height: 320,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 320,
              color: AppColors.muted,
              child: const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.white38,
              ),
            );
          },
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
                  if (restaurant!['phone'] != null)
                    _circleBtn(Icons.call, callRestaurant),
                  if (restaurant!['latitude'] != null ||
                      restaurant!['lat'] != null)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant!['name'] ?? 'Restaurant',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                restaurant!['area'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
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

  Widget _toggleSearchSort() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Text(
            'Alcoholic Only',
            style: TextStyle(color: Colors.white70),
          ),
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
                border: InputBorder.none,
              ),
              onChanged: (v) {
                searchQuery = v;
                filterAndSort();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSection() {
    if (filteredBeverages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No beverages found',
            style: TextStyle(color: Colors.white60),
          ),
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
      onTap: () => context.push('/beverage/${bev['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                bev['image'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: AppColors.muted,
                    child: const Icon(
                      Icons.local_drink,
                      size: 40,
                      color: Colors.white38,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bev['name'] ?? 'Beverage',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bev['type'] ?? '',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${bev['price'] ?? 0}',
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
}
