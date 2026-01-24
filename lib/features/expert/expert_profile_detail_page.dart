import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../config/env_config.dart';

class ExpertProfileDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String expertId;

  const ExpertProfileDetailPage({
    super.key,
    required this.user,
    required this.expertId,
  });

  @override
  State<ExpertProfileDetailPage> createState() =>
      _ExpertProfileDetailPageState();
}

class _ExpertProfileDetailPageState extends State<ExpertProfileDetailPage> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? expert;
  List expertRatings = [];
  bool loading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchExpertProfile();
  }

  Future<void> fetchExpertProfile() async {
    // COMMENTED FOR LOCAL TESTING
    /*
    setState(() { loading = true; hasError = false; });
    try {
      final headers = await _getHeaders();
      final expertRes = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/experts/${widget.expertId}'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      if (expertRes.statusCode == 200) {
        final data = jsonDecode(expertRes.body);
        setState(() {
          expert = data['success'] == true ? data['data'] : data;
        });
      }
      
      final ratingsRes = await http.get(
        Uri.parse('${EnvConfig.apiBaseUrl}/experts/${widget.expertId}/ratings?limit=10'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      if (ratingsRes.statusCode == 200) {
        final data = jsonDecode(ratingsRes.body);
        setState(() {
          expertRatings = data['success'] == true ? (data['data'] ?? []) : [];
        });
      }
    } catch (e) {
      setState(() => hasError = true);
    } finally {
      setState(() => loading = false);
    }
    */

    // DUMMY DATA
    setState(() {
      expert = {
        'id': widget.expertId,
        'name': 'Raj Mehta - Updated',
        'specialization': 'Sommelier',
        'avatar': '',
        'verified': true,
        'avgRating': 4.2,
        'totalRatings': 5,
        'yearsExp': 12,
        'bio':
            'Expert sommelier with 15+ years of experience in beverage tasting and evaluation.',
        'expertise_tags': [
          'Cocktails',
          'Wine',
          'Whiskey',
          'Craft Beer',
          'Mocktails'
        ],
      };

      expertRatings = [
        {
          'beverages': {'name': 'Bangalore Old Fashioned'},
          'presentationRating': 4,
          'tasteRating': 4,
          'ingredientsRating': 4,
          'accuracyRating': 5,
          'createdAt': '2025-12-10'
        },
        {
          'beverages': {'name': 'Purple Rain Martini'},
          'presentationRating': 5,
          'tasteRating': 4,
          'ingredientsRating': 5,
          'accuracyRating': 4,
          'createdAt': '2025-12-08'
        },
      ];

      loading = false;
    });
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

    if (hasError || expert == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              const Text('Failed to load profile'),
              const SizedBox(height: 24),
              AppTheme.gradientButtonPurple(
                onPressed: fetchExpertProfile,
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          _buildQuickStats(),
          _buildAboutSection(),
          _buildSpecializations(),
          _buildRecentRatings(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondary.withOpacity(0.3),
            AppTheme.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.secondary),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified,
                            color: AppTheme.secondary, size: 14),
                        SizedBox(width: 6),
                        Text('SipZy Expert',
                            style: TextStyle(
                                color: AppTheme.secondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.secondary,
                  child: expert!['avatar'] != null &&
                          expert!['avatar'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(expert!['avatar'],
                              width: 120, height: 120, fit: BoxFit.cover))
                      : Text(expert!['name'][0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 48, color: Colors.white)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 3),
                    ),
                    child: const Icon(Icons.verified,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(expert!['name'],
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Text(expert!['specialization'],
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Quick Stats',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('${expert!['totalRatings']}', 'Total Ratings',
                  Icons.star, AppTheme.primary),
              _buildStatCard('${expert!['avgRating']}', 'Avg Score',
                  Icons.trending_up, AppTheme.secondary),
              _buildStatCard('${expert!['yearsExp']}', 'Years Exp',
                  Icons.calendar_today, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withOpacity(0.2)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            const Row(
              children: [
                Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('About the Expert',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            Text(expert!['bio'] ?? '',
                style: const TextStyle(
                    color: AppTheme.textSecondary, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializations() {
    final tags = expert!['expertise_tags'] as List? ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.style, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text('Specializations',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.secondary.withOpacity(0.5)),
                      ),
                      child: Text(tag.toString(),
                          style: const TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRatings() {
    if (expertRatings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Recent Expert Ratings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...expertRatings.map(
            (rating) {
              final photo = rating['beverages']?['photo'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= IMAGE =================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: photo != null && photo.toString().isNotEmpty
                          ? Image.network(
                              photo,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),

                    const SizedBox(width: 12),

                    // ================= CONTENT =================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Avg Rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rating['beverages']?['name'] ?? 'Beverage',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${((rating['presentationRating'] + rating['tasteRating'] + rating['ingredientsRating'] + rating['accuracyRating']) / 4).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Ratings Row 1
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRatingItem(
                                  'Presentation', rating['presentationRating']),
                              _buildRatingItem('Taste', rating['tasteRating']),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Ratings Row 2
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRatingItem(
                                  'Ingredients', rating['ingredientsRating']),
                              _buildRatingItem(
                                  'Accuracy', rating['accuracyRating']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.local_bar,
        color: AppTheme.textTertiary,
        size: 24,
      ),
    );
  }

  Widget _buildRatingItem(String label, int value) {
    return Row(
      children: [
        Text('$label: ',
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ...List.generate(
            5,
            (i) => Icon(
                  i < value ? Icons.star : Icons.star_border,
                  color: AppTheme.primary,
                  size: 12,
                )),
      ],
    );
  }
}
