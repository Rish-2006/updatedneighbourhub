import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/onboarding_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/profile_setup_screen.dart';
import '../../presentation/journey/screens/journey_screen.dart';
import '../../presentation/contacts/screens/trusted_contacts_screen.dart';
import '../../presentation/journey/screens/history_screen.dart';
import '../../presentation/contacts/screens/contact_live_tracking_screen.dart';
import '../../presentation/web/screens/web_live_tracking_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;
      final isWebTracking = loc.startsWith('/track/');
      final isContactTracking = loc.startsWith('/contact-track/');
      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';
      final isLoggingIn = loc == '/login';

      // Public web tracking screen requires no auth
      if (isWebTracking) return null;

      // Allow splash & onboarding without forcing redirect
      if (isSplash || isOnboarding) return null;

      final user = authState.value ?? ref.watch(authRepositoryProvider).currentUser;
      final isAuthenticated = user != null;

      if (!isAuthenticated) {
        if (!isLoggingIn && !isContactTracking) return '/login';
        return null;
      }

      // User is authenticated -> redirect away from login page to home
      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const JourneyScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const TrustedContactsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/track/:journeyId',
        builder: (context, state) {
          final journeyId = state.pathParameters['journeyId'] ?? '';
          return WebLiveTrackingScreen(journeyId: journeyId);
        },
      ),
      GoRoute(
        path: '/contact-track/:journeyId',
        builder: (context, state) {
          final journeyId = state.pathParameters['journeyId'] ?? '';
          return ContactLiveTrackingScreen(journeyId: journeyId);
        },
      ),
    ],
  );
});


