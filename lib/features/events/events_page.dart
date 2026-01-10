import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/env_config.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/bottom_nav.dart';

class EventsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EventsPage({super.key, required this.user});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  static const api = EnvConfig.apiBaseUrl;

  List events = [];
  bool loading = true;
  bool hasError = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final query = searchQuery.isNotEmpty ? '?search=$searchQuery' : '';
      final res = await http.get(Uri.parse('$api/events$query'));

      if (res.statusCode == 200) {
        setState(() {
          events = jsonDecode(res.body);
          hasError = false;
        });
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      setState(() => hasError = true);
      _toast('Failed to load events', isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  void bookNow(Map event) async {
    final uri = Uri.parse('tel:+918012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _toast('Booking ${event['name']}...');
    } else {
      _toast('Unable to make call', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = events.where((e) => e['featured'] == true).toList();
    final trending = events
        .where((e) => e['trending'] == true && e['featured'] != true)
        .toList();
    final more = events
        .where((e) => e['featured'] != true && e['trending'] != true)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: loading
                  ? _buildLoadingSkeleton()
                  : hasError
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: fetchEvents,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.card,
                          child: events.isEmpty
                              ? _buildEmptyState()
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (featured.isNotEmpty)
                                        _buildSection(
                                          'Featured Events',
                                          featured,
                                          tag: 'Featured',
                                        ),
                                      if (trending.isNotEmpty)
                                        _buildSection(
                                          'Trending Near You',
                                          trending,
                                          tag: 'Trending',
                                        ),
                                      if (more.isNotEmpty)
                                        _buildSection('More Events', more),
                                    ],
                                  ),
                                ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'events'),
    );
  }

  // ---------------- HEADER ----------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Events',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Discover exciting events near you',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) {
              searchQuery = v;
              fetchEvents();
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search events...',
              hintStyle: TextStyle(color: AppTheme.textTertiary),
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.glassLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTIONS ----------------

  Widget _buildSection(String title, List list, {String? tag}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tag == 'Featured'
                      ? [AppTheme.primary, AppTheme.primaryLight]
                      : [AppTheme.secondary, AppTheme.secondaryLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...list.map((event) => _buildEventCard(event, tag: tag)),
      ],
    );
  }

  // ---------------- EVENT CARD ----------------

  Widget _buildEventCard(Map event, {String? tag}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
                child: Image.network(
                  event['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.glassLight,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLg),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 48,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image unavailable',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Tag Badge
              if (tag != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: tag == 'Featured'
                            ? [AppTheme.primary, AppTheme.primaryLight]
                            : [AppTheme.secondary, AppTheme.secondaryLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (tag == 'Featured'
                                  ? AppTheme.primary
                                  : AppTheme.secondary)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tag == 'Featured'
                              ? Icons.star_rounded
                              : Icons.trending_up_rounded,
                          size: 14,
                          color:
                              tag == 'Featured' ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: TextStyle(
                            color:
                                tag == 'Featured' ? Colors.black : Colors.white,
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

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['name'],
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  event['description'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Date & Location
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: event['date'],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.location_on_rounded,
                        label: event['location'],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: tag == 'Featured'
                      ? AppTheme.gradientButtonAmber(
                          onPressed: () => bookNow(event),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.phone_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : AppTheme.gradientButtonPurple(
                          onPressed: () => bookNow(event),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.phone_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LOADING SKELETON ----------------

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.card,
          highlightColor: AppTheme.glassLight,
          child: Container(
            height: 320,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
            ),
          ),
        );
      },
    );
  }

  // ---------------- ERROR STATE ----------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to load events',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppTheme.gradientButtonPurple(
              onPressed: fetchEvents,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Retry'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 64,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No events found',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Check back later for upcoming events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: 32),
                AppTheme.gradientButtonPurple(
                  onPressed: () {
                    setState(() => searchQuery = '');
                    fetchEvents();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.clear_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Clear Search'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
