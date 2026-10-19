// lib/main.dart
//
// Entry point of the NeighbourHub application.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_model.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/safety/emergency_screen.dart';
import 'screens/safety/report_issue_screen.dart';

import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  // Load saved theme preference (light/dark mode)
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    // MultiProvider injects our services into the widget tree
    // so any screen can access them easily
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(isDarkMode, prefs),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: const NeighbourHubApp(),
    ),
  );
}

// ─── Theme Controller ────────────────────────────────────────────────────────
// Manages switching between light and dark mode and saves preference
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode;
  final SharedPreferences _prefs;

  ThemeController(bool isDarkMode, this._prefs)
    : _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }
}

// ─── Main App Widget ──────────────────────────────────────────────────────────
class NeighbourHubApp extends StatelessWidget {
  const NeighbourHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'NeighbourHub',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      themeMode: themeController.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // App Routing
      home: const AuthWrapper(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const HomeScreen(),
        AppRoutes.emergency: (context) => const EmergencyScreen(),
        AppRoutes.reportIssue: (context) => const ReportIssueScreen(),
      },
    );
  }
}

// ─── Auth Wrapper ─────────────────────────────────────────────────────────────
// Listens to Firebase Auth state.
// If logged in -> Shows HomeScreen AND saves the user profile to Firestore
// If logged out -> Shows LoginScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // While checking auth state, show a loading spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user is logged in, upsert their profile to Firestore so they
            // appear in the Members list for other users, then show home.
            if (snapshot.hasData && snapshot.data != null) {
              final firebaseUser = snapshot.data!;
              final firestoreService = context.read<FirestoreService>();
              // Use merge:true so we don't overwrite custom fields like neighbourhood/bio
              final userModel = UserModel(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'Neighbour',
                email: firebaseUser.email ?? '',
                photoUrl: firebaseUser.photoURL ?? '',
                neighbourhood: 'Green Valley Community',
                createdAt: DateTime.now(),
              );
              firestoreService.saveUser(userModel);
              return const HomeScreen();
            }

            // Otherwise, show the login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
}
