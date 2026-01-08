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

class SipZyApp extends StatefulWidget {
  const SipZyApp({super.key});

  @override
  State<SipZyApp> createState() => _SipZyAppState();
}

class _SipZyAppState extends State<SipZyApp> {
  final auth = AuthState();
  bool showSplash = true;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => showSplash = false);
      }
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      // Always show splash first
      if (showSplash) return '/splash';

      final location = state.matchedLocation;
      final isAuthRoute = location == '/auth';
      final isExpertAuth = location == '/expert/auth';

      // Expert routes protection
      if (!auth.isExpertLoggedIn &&
          location.startsWith('/expert') &&
          !isExpertAuth) {
        return '/expert/auth';
      }

      // Customer routes protection
      if (!auth.isUserLoggedIn &&
          !location.startsWith('/expert') &&
          !isAuthRoute) {
        return '/auth';
      }

      // Redirect to home if already logged in
      if (auth.isUserLoggedIn && isAuthRoute) return '/';

      // Redirect to expert dashboard if already logged in
      if (auth.isExpertLoggedIn && isExpertAuth) return '/expert';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      /// ---------------- Customer ----------------
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

      /// ---------------- Expert ----------------
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
      theme: ThemeData.dark(),
    );
  }
}
