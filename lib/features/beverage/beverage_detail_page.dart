import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/ui/share_modal.dart';
import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';

class BeverageDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String beverageId;

  const BeverageDetailPage({
    super.key,
    required this.user,
    required this.beverageId,
  });

  @override
  State<BeverageDetailPage> createState() => _BeverageDetailPageState();
}

class _BeverageDetailPageState extends State<BeverageDetailPage> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? beverage;
  bool loading = true;
  bool hasError = false;

  bool showRatingDialog = false;
  bool showReviewsDialog = false;
  bool showExpertBreakdown = false;

  int rating = 0;
  String review = '';
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchBeverage();
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

  Future<void> fetchBeverage() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final headers = await _getHeaders();
      final uri =
          Uri.parse('${EnvConfig.apiBaseUrl}/beverages/${widget.beverageId}');

      print('📡 Fetching beverage from: $uri');

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            // Handle both response formats
            if (data is Map &&
                data.containsKey('success') &&
                data['success'] == true) {
              beverage = data['data'] as Map<String, dynamic>?;
            } else if (data is Map) {
              beverage = data.cast<String, dynamic>();
            }

            hasError = false;
          });
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          _toast('Session expired. Please login again.', isError: true);
          context.go('/auth');
        }
      } else {
        throw Exception('Failed to load beverage: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch beverage error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load beverage details', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> submitRating() async {
    if (rating == 0) {
      _toast('Please select a rating', isError: true);
      return;
    }

    setState(() => submitting = true);

    try {
      final headers = await _getHeaders();

      await http.post(
        Uri.parse(
            '${EnvConfig.apiBaseUrl}/beverages/${widget.beverageId}/rate'),
        headers: headers,
        body: jsonEncode({
          'user_id': widget.user['id'],
          'rating': rating,
          'review': review,
        }),
      );

      _toast('Rating submitted!');
      setState(() {
        rating = 0;
        review = '';
        showRatingDialog = false;
      });

      fetchBeverage();
    } catch (e) {
      print('❌ Submit rating error: $e');
      _toast('Failed to submit rating', isError: true);
    } finally {
      setState(() => submitting = false);
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
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (hasError || beverage == null) {
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
                    'Failed to load beverage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  AppTheme.gradientButtonAmber(
                    onPressed: fetchBeverage,
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

    // Extract ratings
    final ratings = beverage!['ratings'] as Map<String, dynamic>? ?? {};
    final avgHuman = ratings['avgHuman'] ?? ratings['avghuman'] ?? 0;
    final countHuman = ratings['countHuman'] ?? ratings['counthuman'] ?? 0;
    final avgExpert = ratings['avgExpert'] ?? ratings['avgexpert'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRatingsSection(avgHuman, countHuman, avgExpert),
          const SizedBox(height: 16),
          _buildDetailsSection(),
          const SizedBox(height: 16),
          _buildActionsSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final photo = beverage!['photo'];
    final name = beverage!['name'] ?? 'Beverage';
    final category =
        beverage!['category'] ?? beverage!['drinkType'] ?? 'Beverage';

    return Stack(
      children: [
        // Image
        if (photo != null && photo.toString().isNotEmpty)
          Image.network(
            photo,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        else
          _buildPlaceholderImage(),

        // Gradient overlay
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

        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: _buildCircleButton(
            Icons.arrow_back_rounded,
            () => Navigator.pop(context),
          ),
        ),

        // Beverage info
        Positioned(
          bottom: 24,
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
              const SizedBox(height: 6),
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
                  category,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 360,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_rounded,
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
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildRatingsSection(
      dynamic avgHuman, dynamic countHuman, dynamic avgExpert) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRatingCard(
            label: 'SipZy Rating',
            value: 0.0, // Not in API response
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _buildRatingCard(
            label: 'Customer Rating',
            value: avgHuman,
            color: AppTheme.secondary,
            subtitle: '$countHuman reviews',
            onTap: () => setState(() => showReviewsDialog = true),
          ),
          const SizedBox(height: 12),
          _buildRatingCard(
            label: 'Expert Rating',
            value: avgExpert,
            color: Colors.green,
            onTap: () => setState(() => showExpertBreakdown = true),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard({
    required String label,
    required dynamic value,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final ratingValue = (value is num ? value.toDouble() : 0.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.star_rounded, color: color, size: 24),
                const SizedBox(width: 6),
                Text(
                  ratingValue.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final description = beverage!['description'] ?? '';
    final price = beverage!['price'] ?? 0;
    final baseType = beverage!['baseType'] ?? beverage!['basetype'] ?? 'N/A';
    final category = beverage!['category'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              _buildDetailRow('Description', description),
            _buildDetailRow('Price', '₹$price'),
            _buildDetailRow('Base Drink', baseType),
            _buildDetailRow('Category', category),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: AppTheme.gradientButtonAmber(
                onPressed: () => setState(() => showRatingDialog = true),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Add Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ShareModal(
                  open: true,
                  onClose: () => Navigator.pop(context),
                  item: {
                    'title': beverage!['name'] ?? 'Beverage',
                    'description': 'Check out this beverage on SipZy!',
                    'url': 'https://sipzy.co.in/beverage/${widget.beverageId}',
                  },
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
