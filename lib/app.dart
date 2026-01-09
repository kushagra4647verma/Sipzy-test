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
import 'features/games/games_page.dart';
import 'features/events/events_page.dart';
import 'features/social/social_page.dart';

// Expert
import 'features/expert/expert_dashboard.dart';
import 'features/expert/expert_profile_page.dart';
import 'features/expert/expert_tasks_page.dart';

// Theme
import 'core/theme/app_theme.dart';

class SipZyApp extends StatefulWidget {
  const SipZyApp({super.key});

  @override
  State<SipZyApp> createState() => _SipZyAppState();
}

class _SipZyAppState extends State<SipZyApp> {
  final auth = AuthState();
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();

    // Auto-navigate after splash
    _splashTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // This will trigger a navigation after splash
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // If on splash page, let the splash screen handle its own navigation
      if (location == '/splash') {
        return null;
      }

      final isAuthRoute = location == '/auth';
      final isExpertAuth = location == '/expert/auth';

      // Expert routes protection
      if (location.startsWith('/expert') && !isExpertAuth) {
        if (!auth.isExpertLoggedIn) {
          return '/expert/auth';
        }
        return null;
      }

      // Redirect expert to dashboard if already logged in
      if (auth.isExpertLoggedIn && isExpertAuth) {
        return '/expert';
      }

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
            // Navigate to auth after splash completes
            context.go('/auth');
          },
        ),
      ),

      /// ---------------- Customer Routes ----------------
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => AuthPage(
          onLogin: (user) {
            setState(() {
              auth.user = user;
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
        path: '/games',
        name: 'games',
        builder: (context, state) => GamesPage(user: auth.user!),
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
              auth.user = null;
            });
          },
        ),
      ),

      /// ---------------- Expert Routes ----------------
      GoRoute(
        path: '/expert/auth',
        name: 'expert-auth',
        builder: (context, state) => AuthPage(
          onLogin: (expert) {
            setState(() {
              auth.expert = expert;
            });
          },
        ),
      ),
      GoRoute(
        path: '/expert',
        name: 'expert',
        builder: (context, state) => ExpertDashboard(expert: auth.expert!),
      ),
      GoRoute(
        path: '/expert/tasks',
        name: 'expert-tasks',
        builder: (context, state) => ExpertTasksPage(expert: auth.expert!),
      ),
      GoRoute(
        path: '/expert/profile',
        name: 'expert-profile',
        builder: (context, state) => ExpertProfilePage(
          expert: auth.expert!,
          onLogout: () {
            setState(() {
              auth.expert = null;
            });
          },
        ),
      ),
    ],
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
