import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RatingsTab extends StatelessWidget {
  final List ratings;
  final VoidCallback onRefresh;

  const RatingsTab({
    super.key,
    required this.ratings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length,
      itemBuilder: (_, i) => _RatingCard(rating: ratings[i]),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No ratings yet',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start rating beverages to build\nyour credibility',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final Map rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final beverage = rating['beverage'] as Map? ?? {};
    final beverageId =
        beverage['id'] ?? rating['beverageId'] ?? rating['beverage_id'];
    final beverageName =
        beverage['name'] ?? rating['beverage_name'] ?? 'Beverage';
    final restaurantName = rating['restaurant_name'] ??
        rating['restaurantName'] ??
        beverage['restaurant_name'] ??
        '';
    final userRating = rating['rating'] ?? 0;
    final comments = rating['comments'] ?? '';
    final createdAt = rating['createdAt'] ?? rating['created_at'] ?? '';
    final photo = beverage['photo'] ?? rating['photo'];

    return GestureDetector(
      onTap: () {
        if (beverageId != null) {
          context.push('/beverage/$beverageId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beverage Image
            _buildThumbnail(photo),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beverage Name
                  Text(
                    beverageName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Restaurant Name
                  if (restaurantName.isNotEmpty)
                    Text(
                      restaurantName,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Rating Stars
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < userRating ? Icons.star : Icons.star_border,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  // Comments
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comments,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(dynamic photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: photo != null && photo.toString().isNotEmpty
          ? Image.network(
              photo.toString(),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.local_bar_rounded,
        color: AppTheme.textTertiary,
        size: 32,
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
