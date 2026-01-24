import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_state.dart';

// Pages
import 'features/auth/splash_screen.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/restaurant/restaurant_detail.dart';
import 'features/beverage/beverage_detail_page.dart';
import 'features/events/events_page.dart';
import 'features/social/social_page.dart';
import 'features/expert/expert_page.dart';
import 'features/expert/expert_profile_detail_page.dart';

// Theme
import 'core/theme/app_theme.dart';

class SipZyApp extends StatefulWidget {
  const SipZyApp({super.key});

  @override
  State<SipZyApp> createState() => _SipZyAppState();
}

class _SipZyAppState extends State<SipZyApp> {
  final auth = AuthState();
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    await auth.loadSession();
    if (mounted) {
      setState(() {});
    }
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Stay on splash until it completes
      if (!_splashComplete && location != '/splash') {
        return '/splash';
      }

      // Don't redirect if on splash
      if (location == '/splash') {
        return null;
      }

      final isAuthRoute = location == '/auth';

      // Customer routes protection (exclude expert routes)
      if (!location.startsWith('/expert') && !isAuthRoute) {
        if (!auth.isUserLoggedIn) {
          return '/auth';
        }
        return null;
      }

      // Redirect customer to home if already logged in
      if (auth.isUserLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashScreen(
          onComplete: () {
            setState(() => _splashComplete = true);
            context.go('/auth');
          },
        ),
      ),

      /// ---------------- Customer Routes ----------------
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => AuthPage(
          onLogin: (data) {
            setState(() {
              auth.user = data['user'];
              auth.userToken = data['token'];
            });
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => HomePage(user: auth.user!),
      ),
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurant',
        builder: (_, state) => RestaurantDetail(
          user: auth.user!,
          restaurantId: state.pathParameters['id']!,
        ),
      ),

      GoRoute(
        path: '/beverage/:id',
        name: 'beverage',
        builder: (_, state) => BeverageDetailPage(
          user: auth.user!,
          beverageId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => EventsPage(user: auth.user!),
      ),
      GoRoute(
        path: '/social',
        name: 'social',
        builder: (context, state) => SocialPage(
          user: auth.user!,
          onLogout: () {
            setState(() {
              auth.clearUser();
            });
          },
        ),
      ),

      GoRoute(
        path: '/expert-corner',
        name: 'expert-corner',
        builder: (context, state) => ExpertCornerPage(user: auth.user!),
      ),

      /// This must come AFTER /expert-corner to avoid route conflict
      GoRoute(
        path: '/expert/:expertId',
        name: 'expert-detail',
        builder: (context, state) {
          final expertId = state.pathParameters['expertId']!;
          return ExpertProfileDetailPage(
            user: auth.user!,
            expertId: expertId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SipZy',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.darkTheme,
    );
  }
}
