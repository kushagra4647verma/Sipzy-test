import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import 'package:go_router/go_router.dart';

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
  static const api = String.fromEnvironment('API_URL');

  Map<String, dynamic>? beverage;
  bool loading = true;

  bool showRatingDialog = false;
  bool showReviewsDialog = false;
  bool showExpertBreakdown = false;

  int rating = 0;
  String review = '';
  bool submitting = false;

  Map<String, dynamic>? shareItem;

  @override
  void initState() {
    super.initState();
    fetchBeverage();
  }

  Future<void> fetchBeverage() async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse('$api/beverages/${widget.beverageId}'),
      );
      setState(() => beverage = jsonDecode(res.body));
    } catch (_) {
      _toast('Failed to load beverage details');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> submitRating() async {
    if (rating == 0) {
      _toast('Please select a rating');
      return;
    }

    setState(() => submitting = true);

    try {
      await http.post(
        Uri.parse('$api/beverages/${widget.beverageId}/rate'),
        headers: {'Content-Type': 'application/json'},
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
    } catch (_) {
      _toast('Failed to submit rating');
    } finally {
      setState(() => submitting = false);
    }
  }

  Future<void> uploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$api/beverages/${widget.beverageId}/upload-photo'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      _toast('Photo uploaded!');
      fetchBeverage();
    } else {
      _toast('Failed to upload photo');
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

    if (beverage == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _header(),
          _ratingsSection(),
          _detailsSection(),
          if (beverage!['restaurant'] != null) _restaurantCard(),
          _actions(),
          if ((beverage!['reviews'] ?? []).isNotEmpty) _reviewsPreview(),
        ],
      ),
    );
  }

  // ---------------- Header ----------------

  Widget _header() {
    return Stack(
      children: [
        Image.network(
          beverage!['image'],
          height: 360,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
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
          child: _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                beverage!['name'],
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  beverage!['type'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // ---------------- Ratings ----------------

  Widget _ratingsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ratingCard(
            label: 'SipZy Rating',
            value: beverage!['sipzy_rating'] ?? 0,
            color: AppColors.primary,
          ),
          _ratingCard(
            label: 'Customer Rating',
            value: beverage!['customer_rating'] ?? 0,
            color: Colors.purple,
            subtitle: '${beverage!['customer_rating_count'] ?? 0} reviews',
            onTap: () => setState(() => showReviewsDialog = true),
          ),
          _ratingCard(
            label: 'Expert Rating',
            value: beverage!['expert_rating'] ?? 0,
            color: Colors.green,
            onTap: () => setState(() => showExpertBreakdown = true),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard({
    required String label,
    required dynamic value,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60)),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.star, color: color),
                const SizedBox(width: 6),
                Text(
                  value.toString(),
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

  // ---------------- Details ----------------

  Widget _detailsSection() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detailRow('Description', beverage!['description']),
          _detailRow('Price', '₹${beverage!['price']}'),
          _detailRow('Base Drink', beverage!['base_drink']),
          _detailRow(
            'Type',
            beverage!['alcoholic'] ? 'Alcoholic' : 'Non-Alcoholic',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Restaurant ----------------

  Widget _restaurantCard() {
    final r = beverage!['restaurant'];

    return GestureDetector(
      onTap: () => context.go('/restaurant/${r['id']}'),
      child: _card(
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                r['image'],
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'], style: const TextStyle(color: Colors.white)),
                Text(r['area'], style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Actions ----------------

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => showRatingDialog = true),
              icon: const Icon(Icons.star),
              label: const Text('Add Rating'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: uploadPhoto,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                shareItem = {
                  'title': beverage!['name'],
                  'description':
                      '${beverage!['type']} • ₹${beverage!['price']}',
                };
              });
            },
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------- Reviews ----------------

  Widget _reviewsPreview() {
    final reviews = beverage!['reviews'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Reviews',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...reviews.take(3).map<Widget>((r) => _reviewTile(r)),
        ],
      ),
    );
  }

  Widget _reviewTile(Map r) {
    return _card(
      Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: Text(r['user_name'][0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['user_name'],
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  r['review'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}
