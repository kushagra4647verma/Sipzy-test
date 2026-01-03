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
    refreshListenable: Listenable.merge([]),
    redirect: (context, state) {
      if (showSplash) return '/splash';

      final location = state.matchedLocation;
      final isAuthRoute = location == '/auth';
      final isExpertAuth = location == '/expert/auth';

      if (!auth.isUserLoggedIn &&
          location.startsWith('/expert') &&
          !isExpertAuth) {
        return '/expert/auth';
      }

      if (!auth.isUserLoggedIn &&
          !location.startsWith('/expert') &&
          !isAuthRoute) {
        return '/auth';
      }

      if (auth.isUserLoggedIn && isAuthRoute) return '/';

      if (auth.isExpertLoggedIn && isExpertAuth) return '/expert';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      /// ---------------- Customer ----------------
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (_, __) => AuthPage(
          onLogin: (user) {
            auth.user = user;
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (_, __) => HomePage(user: auth.user!),
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
        builder: (_, __) => GamesPage(user: auth.user!),
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (_, __) => EventsPage(user: auth.user!),
      ),
      GoRoute(
        path: '/social',
        name: 'social',
        builder: (_, __) => SocialPage(
          user: auth.user!,
          onLogout: () {
            auth.user = null;
          },
        ),
      ),

      /// ---------------- Expert ----------------
      GoRoute(
        path: '/expert',
        name: 'expert',
        builder: (_, __) => ExpertDashboard(expert: auth.expert!),
      ),
      GoRoute(
        path: '/expert/profile',
        name: 'expert-profile',
        builder: (_, __) => ExpertProfilePage(
          expert: auth.expert!,
          onLogout: () {
            auth.expert = null;
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
