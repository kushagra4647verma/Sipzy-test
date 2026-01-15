import 'package:flutter/material.dart';
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

class _GroupMixMagicDialogState extends State<GroupMixMagicDialog>
    with SingleTickerProviderStateMixin {
  int participants = 1;
  List<String> selectedBaseDrinks = [];
  bool isGenerating = false;
  bool showResults = false;
  List<Map<String, dynamic>> recommendations = [];

  late AnimationController _animationController;

  // Get unique base drinks from beverages
  List<String> get baseDrinks {
    final drinks = <String>{};
    for (final bev in widget.beverages) {
      final baseDrink = bev['base_drink'] ?? bev['baseDrink'];
      if (baseDrink != null && baseDrink.toString().isNotEmpty) {
        drinks.add(baseDrink.toString());
      }
    }
    return drinks.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateParticipants(int count) {
    setState(() {
      participants = count;
      selectedBaseDrinks = List.filled(count, '');
    });
  }

  void _handleGenerate() {
    if (participants < 1) {
      _showToast('Please enter number of participants');
      return;
    }

    if (selectedBaseDrinks.any((d) => d.isEmpty)) {
      _showToast('Please select base drink for all $participants participants');
      return;
    }

    setState(() {
      isGenerating = true;
      showResults = false;
    });

    _animationController.repeat();

    // Simulate slot machine effect
    Future.delayed(const Duration(milliseconds: 2500), () {
      final recs = <Map<String, dynamic>>[];

      for (final baseDrink in selectedBaseDrinks) {
        final filteredBeverages = widget.beverages
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

        // Sort by sipzy_rating
        filteredBeverages.sort((a, b) {
          final aRating = (a['sipzy_rating'] ?? 0) as num;
          final bRating = (b['sipzy_rating'] ?? 0) as num;
          return bRating.compareTo(aRating);
        });

        // Get random from top 3
        final topBeverages = filteredBeverages.take(3).toList();
        if (topBeverages.isNotEmpty) {
          final randomIndex = DateTime.now().millisecond % topBeverages.length;
          recs.add(topBeverages[randomIndex]);
        }
      }

      _animationController.stop();

      setState(() {
        recommendations = recs;
        isGenerating = false;
        showResults = true;
      });
    });
  }

  void _resetForm() {
    setState(() {
      participants = 1;
      selectedBaseDrinks = [];
      isGenerating = false;
      recommendations = [];
      showResults = false;
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: showResults ? _buildResults() : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                onPressed: () => Navigator.pop(context),
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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number of Participants
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

        // Generate Button or Loading
        if (!isGenerating)
          AppTheme.gradientButtonAmber(
            onPressed: _handleGenerate,
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

  Widget _buildResults() {
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
              onPressed: _resetForm,
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
              final cocktail = recommendations[index];
              return _buildCocktailCard(cocktail, index);
            },
          ),
      ],
    );
  }

  Widget _buildCocktailCard(Map<String, dynamic> cocktail, int index) {
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
}
