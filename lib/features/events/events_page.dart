import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../core/theme/app_theme.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../config/env_config.dart';

class EventsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EventsPage({super.key, required this.user});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _supabase = Supabase.instance.client;

  List events = [];
  bool loading = true;
  bool hasError = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchEvents();
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

  Future<void> fetchEvents() async {
    // setState(() {
    //   loading = true;
    //   hasError = false;
    // });

    // try {
    //   final headers = await _getHeaders();
    //   final uri = Uri.parse('${EnvConfig.apiBaseUrl}/events');

    //   print('📡 Fetching events from: $uri');

    //   final res = await http.get(uri, headers: headers).timeout(
    //     const Duration(seconds: 15),
    //     onTimeout: () {
    //       throw TimeoutException('Request timed out');
    //     },
    //   );

    //   print('📡 Response status: ${res.statusCode}');

    //   if (res.statusCode == 200) {
    //     final data = jsonDecode(res.body);

    //     if (mounted) {
    //       setState(() {
    //         if (data is Map &&
    //             data.containsKey('success') &&
    //             data['success'] == true) {
    //           events = (data['data'] as List? ?? []);
    //         } else if (data is List) {
    //           events = data;
    //         } else {
    //           events = (data['data'] as List? ?? []);
    //         }

    //         // Apply search filter if needed
    //         if (searchQuery.isNotEmpty) {
    //           events = events.where((e) {
    //             final name = (e['name'] ?? '').toString().toLowerCase();
    //             final description =
    //                 (e['description'] ?? '').toString().toLowerCase();
    //             final query = searchQuery.toLowerCase();

    //             return name.contains(query) || description.contains(query);
    //           }).toList();
    //         }

    //         hasError = false;
    //       });
    //     }
    //   } else if (res.statusCode == 401) {
    //     if (mounted) {
    //       _toast('Session expired. Please login again.', isError: true);
    //       context.go('/auth');
    //     }
    //   } else {
    //     throw Exception('Failed to load events: ${res.statusCode}');
    //   }
    // } on TimeoutException {
    //   print('❌ Request timeout');
    //   if (mounted) {
    //     setState(() => hasError = true);
    //     _toast('Request timed out. Please try again.', isError: true);
    //   }
    // } catch (e) {
    //   print('❌ Fetch events error: $e');
    //   if (mounted) {
    //     setState(() => hasError = true);
    //     _toast('Failed to load events', isError: true);
    //   }
    // } finally {
    //   if (mounted) {
    //     setState(() => loading = false);
    //   }
    // }

    setState(() {
      events = [
        {
          'id': 1,
          'name': 'Wine Tasting Evening',
          'description': 'Premium wine selection',
          'photo': '',
          'eventdate': '2026-01-25',
          'eventtime': '19:00'
        },
        {
          'id': 2,
          'name': 'Craft Beer Festival',
          'description': 'Local breweries showcase',
          'photo': '',
          'eventdate': '2026-01-28',
          'eventtime': '18:00'
        },
      ];
      loading = false;
    });
  }

  void bookNow(Map event) async {
    final bookingLink = event['bookinglink'] ?? event['bookingLink'];

    if (bookingLink != null && bookingLink.toString().isNotEmpty) {
      final uri = Uri.parse(bookingLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback to phone call
    final uri = Uri.parse('tel:+918012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (mounted) {
        _toast('Booking ${event['name']}...');
      }
    } else {
      if (mounted) {
        _toast('Unable to make call', isError: true);
      }
    }
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return _buildEventCard(events[index]);
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(active: 'events'),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
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
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
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
              setState(() => searchQuery = v);
              fetchEvents();
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search events...',
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textSecondary),
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

  Widget _buildEventCard(Map event) {
    final eventDate = event['eventdate'] ?? event['eventDate'];
    final eventTime = event['eventtime'] ?? event['eventTime'];
    final photo = event['photo'];
    final name = event['name'] ?? 'Event';
    final description = event['description'] ?? '';

    // Format date and time
    String dateTimeStr = 'Date TBA';
    if (eventDate != null) {
      try {
        final date = DateTime.parse(eventDate.toString());
        dateTimeStr = '${date.day}/${date.month}/${date.year}';
        if (eventTime != null) {
          dateTimeStr += ' at $eventTime';
        }
      } catch (e) {
        dateTimeStr = eventDate.toString().split('T')[0];
        if (eventTime != null) {
          dateTimeStr += ' at $eventTime';
        }
      }
    }

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
          // Event Photo
          if (photo != null && photo.toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
              child: Image.network(
                photo,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            )
          else
            _buildPlaceholderImage(),

          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),

                // Date/Time Info
                Container(
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
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateTimeStr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: AppTheme.gradientButtonPurple(
                    onPressed: () => bookNow(event),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Book Event',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_rounded,
            size: 48,
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
              child: const Icon(
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Retry', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                child: const Icon(
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
                    children: [
                      Icon(Icons.clear_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Clear Search',
                          style: TextStyle(color: Colors.white)),
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
