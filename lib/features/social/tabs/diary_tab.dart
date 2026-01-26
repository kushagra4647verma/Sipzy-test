import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/user_service.dart';
import '../../../services/camera_service.dart';
import '../../../core/theme/app_theme.dart';

class DiaryTab extends StatefulWidget {
  final List diaryEntries;
  final CameraService cameraService;
  final UserService userService;
  final VoidCallback onRefresh;
  final Function(String, {bool isError}) showToast;

  const DiaryTab({
    super.key,
    required this.diaryEntries,
    required this.cameraService,
    required this.userService,
    required this.onRefresh,
    required this.showToast,
  });

  @override
  State<DiaryTab> createState() => DiaryTabState();
}

class DiaryTabState extends State<DiaryTab> {
  final _supabase = Supabase.instance.client;

  Future<void> addDiaryEntry({
    required String bevName,
    required String restaurant,
    required int rating,
    String? notes,
    String? image,
    bool sharedToFeed = false,
  }) async {
    if (bevName.isEmpty || rating < 1 || rating > 5) {
      widget.showToast('Please enter drink name and rating', isError: true);
      return;
    }

    try {
      final success = await widget.userService.addDiaryEntry({
        'bevName': bevName,
        'restaurant': restaurant.isNotEmpty ? restaurant : null,
        'rating': rating,
        'notes': notes?.isNotEmpty == true ? notes : null,
        'image': image,
      });

      if (success) {
        widget.showToast('Diary entry added');
        widget.onRefresh();
      } else {
        widget.showToast('Failed to add diary entry', isError: true);
      }
    } catch (e) {
      widget.showToast('Error adding diary', isError: true);
    }
  }

  Future<void> deleteDiaryEntry(String entryId) async {
    try {
      final success = await widget.userService.deleteDiaryEntry(entryId);

      if (success) {
        widget.showToast('Diary entry deleted');
        widget.onRefresh();
      } else {
        widget.showToast('Failed to delete diary', isError: true);
      }
    } catch (e) {
      widget.showToast('Error deleting diary', isError: true);
    }
  }

  void showAddDiaryDialog() {
    final nameController = TextEditingController();
    final restaurantController = TextEditingController();
    final notesController = TextEditingController();
    int rating = 3;
    bool shareToFeed = false;
    String? uploadedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppTheme.primary,
                            AppTheme.primaryLight
                          ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.book,
                            color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Add Diary Entry',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoUpload(setDialogState, uploadedImageUrl,
                          (url) {
                        setDialogState(() => uploadedImageUrl = url);
                      }),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, 'Drink Name *'),
                      const SizedBox(height: 16),
                      _buildTextField(
                          restaurantController, 'Restaurant / Place',
                          suffix: Icons.search),
                      const SizedBox(height: 20),
                      _buildRatingSelector(rating, (newRating) {
                        setDialogState(() => rating = newRating);
                      }),
                      const SizedBox(height: 16),
                      _buildNotesField(notesController),
                      const SizedBox(height: 16),
                      _buildShareToggle(shareToFeed, (value) {
                        setDialogState(() => shareToFeed = value);
                      }),
                    ],
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            widget.showToast('Please enter drink name',
                                isError: true);
                            return;
                          }

                          Navigator.pop(context);
                          addDiaryEntry(
                            bevName: nameController.text.trim(),
                            restaurant: restaurantController.text.trim(),
                            rating: rating,
                            notes: notesController.text.trim(),
                            image: uploadedImageUrl,
                            sharedToFeed: shareToFeed,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Save Entry',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload(
      StateSetter setState, String? imageUrl, Function(String?) onUpload) {
    return GestureDetector(
      onTap: () async {
        final url = await widget.cameraService.pickAndUpload(
          context: context,
          bucket: 'diary-photos',
          folder: 'user-${_supabase.auth.currentUser?.id}',
        );

        if (url != null) {
          onUpload(url);
          widget.showToast('Photo uploaded successfully');
        }
      },
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl), fit: BoxFit.cover)
              : null,
        ),
        child: imageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo,
                        color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Add Photo',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Camera or Gallery',
                      style: TextStyle(
                          color: AppTheme.textTertiary, fontSize: 11)),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => onUpload(null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {IconData? suffix}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        suffixIcon:
            suffix != null ? Icon(suffix, color: AppTheme.textSecondary) : null,
      ),
    );
  }

  Widget _buildRatingSelector(int rating, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rating',
            style:
                TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: AppTheme.primary,
                size: 36,
              ),
              onPressed: () => onChanged(index + 1),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNotesField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      maxLength: 200,
      decoration: const InputDecoration(
        labelText: 'Notes (optional)',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        helperText: 'Max 200 characters',
        helperStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
      ),
    );
  }

  Widget _buildShareToggle(bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.secondary,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share to Feed',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('Make this visible to your friends',
                    style:
                        TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add Entry button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: showAddDiaryDialog,
            icon: const Icon(Icons.add, color: Colors.black, size: 20),
            label: const Text('Add Entry',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        // Content
        Expanded(
          child: widget.diaryEntries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.diaryEntries.length,
                  itemBuilder: (_, i) => _DiaryCard(
                    entry: widget.diaryEntries[i],
                    onDelete: deleteDiaryEntry,
                    showToast: widget.showToast,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'No diary entries yet. Start documenting\nyour beverage journey!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final Map entry;
  final Function(String) onDelete;
  final Function(String, {bool isError}) showToast;

  const _DiaryCard({
    required this.entry,
    required this.onDelete,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    final entryId = entry['entryId'] ?? entry['entryid'] ?? entry['id'];
    final bevName = entry['bevName'] ?? entry['bev_name'] ?? 'Drink';
    final restaurant = entry['restaurant'] ?? '';
    final rating = entry['rating'] ?? 0;
    final notes = entry['notes'] ?? '';
    final image = entry['image'];
    final createdAt = entry['createdAt'] ?? entry['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildThumbnail(image),
        title: Text(bevName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(restaurant,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                ...List.generate(
                    5,
                    (index) => Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.primary,
                        size: 14)),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(notes,
                  style: const TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          onPressed: () => _confirmDelete(context, entryId),
        ),
      ),
    );
  }

  Widget _buildThumbnail(dynamic image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image != null && image.toString().isNotEmpty
          ? Image.network(image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder())
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.local_bar_rounded,
          color: AppTheme.textTertiary, size: 28),
    );
  }

  void _confirmDelete(BuildContext context, dynamic entryId) {
    if (entryId == null) {
      showToast('Invalid entry ID', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        title:
            const Text('Delete Entry?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(entryId.toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
