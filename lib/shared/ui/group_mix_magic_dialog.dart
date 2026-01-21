import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/theme/app_theme.dart';

class GroupMixMagicDialog extends StatefulWidget {
  final List beverages;
  final Map<String, dynamic> restaurant;

  const GroupMixMagicDialog({
    super.key,
    required this.beverages,
    required this.restaurant,
  });

  @override
  State<GroupMixMagicDialog> createState() => _GroupMixMagicDialogState();
}

class _GroupMixMagicDialogState extends State<GroupMixMagicDialog> {
  List<Map<String, dynamic>> recommendations = [];
  int numParticipants = 3;

  @override
  void initState() {
    super.initState();
    _generateRecommendations();
  }

  void _generateRecommendations() {
    if (widget.beverages.isEmpty) return;

    final random = Random();
    recommendations = List.generate(numParticipants, (index) {
      final bev = widget.beverages[random.nextInt(widget.beverages.length)];
      return {
        'participant': 'Participant ${index + 1}',
        'beverage': bev,
        'rating': (random.nextDouble() * 2 + 3).toStringAsFixed(1), // 3.0-5.0
      };
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondary.withOpacity(0.3),
              AppTheme.background,
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Icon(Icons.local_bar,
                      color: AppTheme.primary, size: 32),
                ],
              ),
            ),

            // Title
            const Text(
              'Group Mix Magic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let AI create the perfect mix for your group',
              style: TextStyle(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 24),

            // Number of participants selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Participants:',
                      style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (numParticipants > 2) {
                            setState(() => numParticipants--);
                            _generateRecommendations();
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppTheme.primary),
                      ),
                      Text('$numParticipants',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () {
                          if (numParticipants < 6) {
                            setState(() => numParticipants++);
                            _generateRecommendations();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recommendations
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shrinkWrap: true,
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  final bev = rec['beverage'] as Map;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rec['participant'],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bev['name'] ?? 'Beverage',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${bev['price'] ?? 0}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppTheme.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rec['rating'],
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Try Again Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: AppTheme.gradientButtonPurple(
                  onPressed: _generateRecommendations,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Try Again',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
