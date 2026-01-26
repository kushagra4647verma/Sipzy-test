import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/models/restaurant_model.dart';

enum GroupMixStep { participants, baseSelection, result }

class GroupMixMagicDialog extends StatefulWidget {
  final List beverages;
  final Restaurant restaurant;

  const GroupMixMagicDialog({
    super.key,
    required this.beverages,
    required this.restaurant,
  });
  @override
  State<GroupMixMagicDialog> createState() => _GroupMixMagicDialogState();
}

class _GroupMixMagicDialogState extends State<GroupMixMagicDialog> {
  GroupMixStep _step = GroupMixStep.participants;

  int _participants = 3;
  List<String?> _baseDrinks = [];
  List<Map<String, dynamic>> _results = [];
  List<String> _availableSpirits() {
    final set = <String>{};

    for (final b in widget.beverages) {
      final tags = (b['tags'] ?? '').toString().toLowerCase();
      final category = (b['category'] ?? '').toString().toLowerCase();

      for (final s in [
        'vodka',
        'whisky',
        'rum',
        'gin',
        'tequila',
        'wine',
        'beer'
      ]) {
        if (tags.contains(s) || category.contains(s)) {
          set.add(s[0].toUpperCase() + s.substring(1));
        }
      }
    }

    return set.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _baseDrinks = List.filled(_participants, null);
  }

  // ------------------- CORE LOGIC -------------------

  void _generateMix() {
    final random = Random();
    _results.clear();

    for (int i = 0; i < _participants; i++) {
      final base = _baseDrinks[i];

      final filtered = widget.beverages.where((b) {
        final tags = (b['tags'] ?? '').toString().toLowerCase();
        final category = (b['category'] ?? '').toString().toLowerCase();

        if (base == null) return true;
        return tags.contains(base.toLowerCase()) ||
            category.contains(base.toLowerCase());
      }).toList();

      if (filtered.isEmpty) continue;

      final drink = filtered[random.nextInt(filtered.length)];

      _results.add({
        'participant': 'Participant ${i + 1}',
        'beverage': drink,
        'rating': (random.nextDouble() * 2 + 2).toStringAsFixed(1),
      });
    }

    setState(() => _step = GroupMixStep.result);
  }

  // ------------------- UI -------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.background, // ✅ NOT transparent
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: AppTheme.background, // ✅ solid
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 8),
            if (_step == GroupMixStep.participants) _participantsStep(),
            if (_step == GroupMixStep.baseSelection) _baseSelectionStep(),
            if (_step == GroupMixStep.result) _resultStep(),
          ],
        ),
      ),
    );
  }

  // ------------------- HEADER -------------------

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.secondary.withOpacity(0.35),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Icon(Icons.local_bar, color: AppTheme.primary, size: 30),
        ],
      ),
    );
  }

  // ------------------- STEP 1 -------------------

  Widget _participantsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _title(),
          const SizedBox(height: 24),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Number of Participants',
              hintText: 'e.g. 4',
              filled: true,
              fillColor: AppTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0 && n <= 6) {
                setState(() {
                  _participants = n;
                  _baseDrinks = List.filled(n, null);
                  _results.clear();
                });
              }
            },
          ),
          const SizedBox(height: 24),
          _primaryButton('Generate Mix', () {
            setState(() => _step = GroupMixStep.baseSelection);
          }),
        ],
      ),
    );
  }

  // ------------------- STEP 2 -------------------

  Widget _baseSelectionStep() {
    final spirits = _availableSpirits();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _title(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _participants,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      value: _baseDrinks[i],
                      dropdownColor: AppTheme.card,
                      hint: Text(
                        'Participant ${i + 1} – Choose spirit',
                        style: const TextStyle(color: Colors.white),
                      ),
                      items: spirits.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _baseDrinks[i] = v),
                    ),
                  );
                },
              ),
            ),
            _primaryButton('Generate Mix', _generateMix),
          ],
        ),
      ),
    );
  }

  // ------------------- STEP 3 -------------------

  Widget _resultStep() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '✨ Your Perfect Mix',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _generateMix,
                  child: const Text('Try Again'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: _results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final rec = _results[i];
                  final bev = rec['beverage'];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _pill(rec['participant']),
                        const Spacer(),
                        Text(
                          bev['name'] ?? 'Drink',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${bev['price'] ?? 0}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              rec['rating'],
                              style: const TextStyle(color: AppTheme.primary),
                            ),
                          ],
                        ),
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

  // ------------------- HELPERS -------------------

  Widget _title() => const Column(
        children: [
          Text(
            'Group Mix Magic',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            'Let AI create the perfect mix for your group',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      );

  Widget _primaryButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: AppTheme.gradientButtonPurple(
          onPressed: onTap,
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}
