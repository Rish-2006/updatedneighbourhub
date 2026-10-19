// lib/routes/app_routes.dart
//
// This file defines all the screen names (routes) used for navigation.
// Instead of writing the full path "/profile" everywhere in the app,
// we use AppRoutes.profile - this makes it easy to rename routes later.

class AppRoutes {
  // We make the constructor private so no one can create an AppRoutes object
  AppRoutes._();

  // Auth routes
  static const String splash   = '/splash';
  static const String auth     = '/auth';
  static const String login    = '/login';
  static const String register = '/register';

  // Onboarding (first time setup)
  static const String onboarding = '/onboarding';

  // Main app shell (has the bottom navigation bar)
  static const String main = '/main';

  // Individual screens reachable from the main shell
  static const String createPost       = '/create-post';
  static const String postDetails      = '/post-details';
  static const String neighbourProfile = '/neighbour-profile';
  static const String editProfile      = '/edit-profile';
  static const String settings         = '/settings';
  static const String emergency        = '/emergency';
  static const String reportIssue      = '/report-issue';
  static const String lostFound        = '/lost-found';
  static const String help             = '/help';
  static const String events           = '/events';
  static const String announcements    = '/announcements';
}
