import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'services/auth_state.dart';

// Pages
import 'features/auth/splash_screen.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/restaurant/restaurant_detail.dart';
import 'features/restaurant/beverage_detail.dart';
import 'features/games/games_page.dart';
import 'features/events/events_page.dart';
import 'features/social/social_page.dart';
import 'features/expert/expert_list_page.dart';
import 'features/expert/expert_public_profile.dart';

// Expert
import 'features/expert/expert_auth_page.dart';
import 'features/expert/expert_dashboard.dart';
import 'features/expert/expert_tasks.dart';
import 'features/expert/expert_profile.dart';
import 'features/expert/expert_restaurant_detail.dart';
import 'features/expert/expert_beverage_rating.dart';
import 'features/expert/rating_confirmation.dart';

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

    // Mimics useEffect()
    Timer(const Duration(seconds: 2), () {
      setState(() => showSplash = false);
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([]),
    redirect: (context, state) {
      if (showSplash) return '/splash';

      final isAuthRoute = state.location == '/auth';
      final isExpertAuth = state.location == '/expert/auth';

      if (!auth.isUserLoggedIn &&
          state.location.startsWith('/expert') &&
          !isExpertAuth) {
        return '/expert/auth';
      }

      if (!auth.isUserLoggedIn &&
          !state.location.startsWith('/expert') &&
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
        name: '',
        builder: (_, __) => HomePage(user: auth.user!),
      ),
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurant',
        builder: (_, state) =>
            RestaurantDetail(id: state.pathParameters['id']!, user: auth.user!),
      ),
      GoRoute(
        path: '/beverage/:id',
        name: 'beverage',
        builder: (_, state) =>
            BeverageDetail(id: state.pathParameters['id']!, user: auth.user!),
      ),
      GoRoute(
        path: '/games',
        builder: (_, __) => GamesPage(user: auth.user!),
      ),
      GoRoute(
        path: '/events',
        builder: (_, __) => EventsPage(user: auth.user!),
      ),
      GoRoute(
        path: '/social',
        builder: (_, __) =>
            SocialPage(user: auth.user!, onLogout: () => auth.user = null),
      ),
      GoRoute(
        path: '/expert-corner',
        builder: (_, __) => ExpertListPage(user: auth.user!),
      ),
      GoRoute(
        path: '/expert-profile/:id',
        builder: (_, state) => ExpertPublicProfile(
          id: state.pathParameters['id']!,
          user: auth.user!,
        ),
      ),

      /// ---------------- Expert ----------------
      GoRoute(
        path: '/expert/auth',
        builder: (_, __) => ExpertAuthPage(
          onLogin: (expert) {
            auth.expert = expert;
          },
        ),
      ),
      GoRoute(
        path: '/expert',
        builder: (_, __) => ExpertDashboard(expert: auth.expert!),
      ),
      GoRoute(
        path: '/expert/tasks',
        builder: (_, __) => ExpertTasksPage(expert: auth.expert!),
      ),
      GoRoute(
        path: '/expert/profile',
        builder: (_, __) => ExpertProfilePage(
          expert: auth.expert!,
          onLogout: () => auth.expert = null,
        ),
      ),
      GoRoute(
        path: '/expert/restaurant/:id',
        builder: (_, state) => ExpertRestaurantDetail(
          id: state.pathParameters['id']!,
          expert: auth.expert!,
        ),
      ),
      GoRoute(
        path: '/expert/beverage/:id/rate',
        builder: (_, state) => ExpertBeverageRating(
          id: state.pathParameters['id']!,
          expert: auth.expert!,
        ),
      ),
      GoRoute(
        path: '/expert/rating-success',
        builder: (_, __) => RatingConfirmation(expert: auth.expert!),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SipZy',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
