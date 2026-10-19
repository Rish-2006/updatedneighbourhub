// lib/main.dart
// Entry point of the NeighbourHub application.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider, Consumer, ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ FIXED: Using direct relative path to completely eliminate package name conflicts
import 'services/mongodb_service.dart';

import 'neighbour/theme/app_theme.dart';
import 'neighbour/routes/app_routes.dart';
import 'neighbour/services/auth_service.dart';
import 'neighbour/services/firestore_service.dart';
import 'neighbour/models/user_model.dart' as neighbour_model;

import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'neighbour/screens/home/home_screen.dart';
import 'neighbour/screens/safety/emergency_screen.dart';
import 'neighbour/screens/safety/report_issue_screen.dart';
import 'neighbour/constants.dart';
import 'neighbour/screens/admin/admin_dashboard_screen.dart';

import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase core services cleanly
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 2. Load saved theme preference immediately to prevent web initialization hangs
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    // ✅ FIXED: Re-added ProviderScope at the top layer to clear the Bad State crash
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeController(isDarkMode, prefs),
          ),
          ChangeNotifierProvider(create: (_) => AuthService()),
          Provider(create: (_) => FirestoreService()),
          // Inject the web-safe API Service into your application lifecycle
          Provider(create: (_) => MongoDBService()),
        ],
        child: const NeighbourHubApp(),
      ),
    ),
  );
}

// ─── Theme Controller ────────────────────────────────────────────────────────
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
    return MaterialApp(
      title: 'NeighbourHub',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      home: const SplashScreen(),
      routes: {
        AppRoutes.auth: (context) => const AuthWrapper(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const HomeScreen(),
        AppRoutes.emergency: (context) => const EmergencyScreen(),
        AppRoutes.reportIssue: (context) => const ReportIssueScreen(),
      },
    );
  }
}

// ─── Auth Wrapper ─────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              final firebaseUser = snapshot.data!;
              
              if (firebaseUser.email == AppConstants.adminEmail) {
                return const AdminDashboardScreen();
              }

              // ✅ FIXED: Using stable explicit provider lookup method for widgets
              final firestoreService = Provider.of<FirestoreService>(context, listen: false);
              final mongoDBService = Provider.of<MongoDBService>(context, listen: false);
              
              final userModel = neighbour_model.UserModel(
                id: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'Neighbour',
                email: firebaseUser.email ?? '',
                photoUrl: firebaseUser.photoURL ?? '',
                neighbourhood: 'Green Valley Community',
                createdAt: DateTime.now(),
              );
              
              // Executes background profile writes AFTER the frame draws to avoid layout crashes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 1. Keeps legacy fallback operational if needed
                firestoreService.saveUser(userModel);
                
                // 2. Synchronizes data directly to MongoDB Atlas via Node.js server
                mongoDBService.syncUserProfile(
                  uid: firebaseUser.uid,
                  email: firebaseUser.email ?? '',
                  displayName: firebaseUser.displayName,
                  photoUrl: firebaseUser.photoURL,
                );
              });

              return const HomeScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
