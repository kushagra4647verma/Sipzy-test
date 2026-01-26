import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class SavesTab extends StatelessWidget {
  final List bookmarks;
  final UserService userService;
  final VoidCallback onRefresh;
  final Function(String, {bool isError}) showToast;

  const SavesTab({
    super.key,
    required this.bookmarks,
    required this.userService,
    required this.onRefresh,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) => _BookmarkCard(
        bookmark: bookmarks[i],
        onRemove: (id, name) => _confirmRemoveBookmark(context, id, name),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No saved spots yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBookmark(String restaurantId) async {
    try {
      final success = await userService.removeBookmark(restaurantId);

      if (success) {
        showToast('Bookmark removed');
        onRefresh();
      } else {
        showToast('Failed to remove bookmark', isError: true);
      }
    } catch (e) {
      showToast('Error removing bookmark', isError: true);
    }
  }

  void _confirmRemoveBookmark(
      BuildContext context, String restaurantId, String name) {
    if (restaurantId.isEmpty) {
      showToast('Invalid restaurant ID', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Remove Bookmark?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$name" from your saved restaurants?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeBookmark(restaurantId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Map bookmark;
  final Function(String, String) onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Handle different API response formats
    final restaurantId = bookmark['restaurantId'] ??
        bookmark['restaurantid'] ??
        bookmark['restaurant_id'] ??
        bookmark['id'];

    final name = bookmark['name'] ??
        bookmark['restaurantName'] ??
        bookmark['restaurant_name'] ??
        'Restaurant';

    final area =
        bookmark['area'] ?? bookmark['location'] ?? bookmark['address'] ?? '';

    final cuisines =
        bookmark['cuisine'] as List? ?? bookmark['cuisines'] as List? ?? [];

    final logoImage = bookmark['logoImage'] ??
        bookmark['logo_image'] ??
        bookmark['photo'] ??
        bookmark['image'];

    return GestureDetector(
      onTap: () {
        if (restaurantId != null) {
          context.push('/restaurant/$restaurantId');
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
            // Restaurant Image
            _buildThumbnail(logoImage),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location/Area
                  if (area.isNotEmpty)
                    Text(
                      area,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Cuisine Tags
                  if (cuisines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCuisineChips(cuisines),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(dynamic logoImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: logoImage != null && logoImage.toString().isNotEmpty
          ? Image.network(
              logoImage.toString(),
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
        Icons.restaurant,
        color: AppTheme.textTertiary,
        size: 32,
      ),
    );
  }

  Widget _buildCuisineChips(List cuisines) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: cuisines.take(2).map((cuisine) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cuisine.toString(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
