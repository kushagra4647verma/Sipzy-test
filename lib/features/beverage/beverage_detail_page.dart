import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/ui/share_modal.dart';
import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';
import '../../services/beverage_service.dart';
import '../../services/camera_service.dart';
import '../../services/user_service.dart';

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
  final _beverageService = BeverageService();
  final _cameraService = CameraService();
  final _userService = UserService();

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
      final result = await _beverageService.getBeverage(widget.beverageId);

      if (mounted && result != null) {
        setState(() {
          beverage = result;
          hasError = false;
        });
      } else {
        throw Exception('Beverage not found');
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
      final success = await _beverageService.rateBeverage(
        widget.beverageId,
        {
          'rating': rating,
          'review': review,
        },
      );

      if (success) {
        _toast('Rating submitted!');
        setState(() {
          rating = 0;
          review = '';
          showRatingDialog = false;
        });
        fetchBeverage();
      } else {
        _toast('Failed to submit rating', isError: true);
      }
    } catch (e) {
      print('❌ Submit rating error: $e');
      _toast('Failed to submit rating', isError: true);
    } finally {
      setState(() => submitting = false);
    }
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    String reviewText = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text('Rate Bangalore Old Fashioned',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your Rating',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => reviewText = v,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.glassLight,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRating > 0) {
                  Navigator.pop(context);
                  _toast('Rating submitted!');
                  setState(() {
                    // Update local rating
                  });
                } else {
                  _toast('Please select a rating', isError: true);
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Submit Rating',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpertBreakdown() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expert Rating Breakdown',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tap each category to see details',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              _buildExpandableBreakdownItem('Presentation', 4),
              _buildExpandableBreakdownItem('Taste', 3),
              _buildExpandableBreakdownItem('Ingredients', 3),
              _buildExpandableBreakdownItem('Accuracy', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableBreakdownItem(String label, int value) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool expanded = false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => expanded = !expanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                        const SizedBox(width: 8),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                      ],
                    ),
                    Text('$value/5',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 5,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 8,
                ),
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Expert notes: ${_getExpertNotes(label)}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getExpertNotes(String category) {
    switch (category) {
      case 'Presentation':
        return 'Well-crafted garnish and glassware';
      case 'Taste':
        return 'Balanced flavors with good depth';
      case 'Ingredients':
        return 'Fresh, quality ingredients used';
      case 'Accuracy':
        return 'True to classic recipe';
      default:
        return 'No notes available';
    }
  }

  Widget _buildBreakdownItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              Text('$value/5',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerReviews() {
    final reviews = [
      {
        'user': 'Test User',
        'rating': 4.5,
        'comment': 'Great taste!',
        'date': '12/12/2025'
      },
      {
        'user': 'Test User',
        'rating': 4.5,
        'comment': 'Great taste!',
        'date': '12/12/2025'
      },
      {'user': 'Test', 'rating': 4.0, 'comment': 'Test', 'date': '12/5/2025'},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Customer Reviews (${reviews.length})',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.secondary,
                              child: Text(review['user'].toString()[0],
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(review['user'].toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text(review['date'].toString(),
                                      style: const TextStyle(
                                          color: AppTheme.textTertiary,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: AppTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                Text('${review['rating']}',
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(review['comment'].toString(),
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
      onTap: () {
        {
          if (label == 'Customer Rating') {
            _showCustomerReviews();
          } else if (label == 'Expert Rating') {
            _showExpertBreakdown();
          }
        }
      },
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
          // ================= ADD RATING =================
          Expanded(
            child: SizedBox(
              height: 48,
              child: AppTheme.gradientButtonAmber(
                onPressed: () => _showRatingDialog(),
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

          // ================= SHARE =================
          _buildIconAction(
            icon: Icons.share_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ShareModal(
                  onClose: () => Navigator.pop(context),
                  item: {
                    'title': beverage!['name'] ?? 'Beverage',
                    'description': 'Check out this beverage on SipZy!',
                    'url': 'https://sipzy.co.in/beverage/${widget.beverageId}',
                  },
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // ================= PHOTO UPLOAD =================
          _buildIconAction(
            icon: Icons.camera_alt_rounded,
            onTap: _showPhotoUpload,
          ),
        ],
      ),
    );
  }

  void _showPhotoUpload() async {
    final cameraService = CameraService();

    final photoUrl = await cameraService.pickAndUpload(
      context: context,
      bucket: 'beverage-photos',
      folder: 'user-uploads',
      filename: '${widget.beverageId}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (photoUrl != null) {
      // Upload to backend
      final success = await _userService.uploadBeveragePhoto(
        widget.beverageId,
        {
          'url': photoUrl,
          'caption': 'User uploaded photo',
        },
      );

      if (success) {
        _toast('Photo uploaded successfully!');
      } else {
        _toast('Failed to save photo', isError: true);
      }
    }
  }

  Widget _buildIconAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }
}
