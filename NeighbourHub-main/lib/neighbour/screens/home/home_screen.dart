// lib/screens/home/home_screen.dart
//
// The main app shell with bottom navigation bar.
// This screen holds 5 tabs: Home, Neighbours, Community, Notifications, Profile.
// It also contains the home feed with posts and quick action buttons.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../neighbours/neighbours_screen.dart';
import '../community/community_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../posts/create_post_screen.dart';
import '../safety/emergency_screen.dart';
import '../safety/report_issue_screen.dart';
import '../posts/post_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Which tab is currently selected (0=Home, 1=Neighbours, 2=Community, 3=Notifications, 4=Profile)
  int _selectedIndex = 0;

  // The 5 screens for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeFeedTab(),       // Tab 0: Home feed
      const NeighboursScreen(),   // Tab 1: Neighbours list
      const CommunityScreen(),    // Tab 2: Community info
      const NotificationsScreen(),// Tab 3: Notifications
      const ProfileScreen(),      // Tab 4: Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all screens alive when switching tabs
      // (instead of destroying and rebuilding them)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Neighbours',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Feed Tab ─────────────────────────────────────────────────────────────
// This is the content shown on the first tab (Home).
class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> {
  // The current user's profile (loaded from Firestore or mock)
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Get the logged-in Firebase user
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    if (firebaseUser == null) return;

    // Try to load their profile from Firestore
    final firestoreService = context.read<FirestoreService>();
    final user = await firestoreService.getUser(firebaseUser.uid);

    setState(() {
      // If Firestore has their profile, use it. Otherwise build from Firebase auth info.
      _currentUser = user ??
          UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Neighbour',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL ?? '',
            neighbourhood: 'Green Valley Community',
            createdAt: DateTime.now(),
          );
      _isLoading = false;
    });
  }

  // Returns a greeting based on the current time
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _handleLike(PostModel post) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';
    context.read<FirestoreService>().toggleLike(post.id, userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final currentUserId = authService.currentUser?.uid;

    return Scaffold(
      // App Bar
      appBar: AppBar(
        title: const Text('NeighbourHub'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1B2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                      SizedBox(width: 10),
                      Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to log out?',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                try {
                  await context.read<AuthService>().signOut();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil('/auth', (route) => false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              }
            },
          ),
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              // Navigate to notifications tab (index 3)
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.setState(() => homeState._selectedIndex = 3);
            },
          ),
          // Profile avatar
          GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.setState(() => homeState._selectedIndex = 4);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                backgroundImage: (_currentUser?.photoUrl.isNotEmpty == true)
                    ? NetworkImage(_currentUser!.photoUrl)
                    : null,
                child: (_currentUser?.photoUrl.isEmpty != false)
                    ? Text(
                        _currentUser?.name.isNotEmpty == true
                            ? _currentUser!.name[0].toUpperCase()
                            : 'N',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              // Pull down to refresh the feed
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Greeting ──────────────────────────────────────
                          Text(
                            '$_greeting, ${_currentUser?.firstName ?? 'Neighbour'} 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.2, end: 0, duration: 400.ms),

                          const SizedBox(height: 4),

                          // ── Community Name ────────────────────────────────
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentUser?.neighbourhood ??
                                    'Your Community',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 400.ms),

                          const SizedBox(height: 24),

                          // ── Quick Actions ─────────────────────────────────
                          Text(
                            'Quick Actions',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Create Post
                              _QuickActionButton(
                                icon: Icons.edit_outlined,
                                label: 'Create Post',
                                color: AppTheme.primaryColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Emergency
                              _QuickActionButton(
                                icon: Icons.emergency_outlined,
                                label: 'Emergency',
                                color: AppTheme.errorColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const EmergencyScreen()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Report Issue
                              _QuickActionButton(
                                icon: Icons.report_problem_outlined,
                                label: 'Report Issue',
                                color: AppTheme.warningColor,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ReportIssueScreen()),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                          const SizedBox(height: 28),

                          // ── Community Feed Title ───────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Community Feed',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePostScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Post'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                  ),

                  // ── Posts List ────────────────────────────────────────────
                  StreamBuilder<List<PostModel>>(
                    stream: context.read<FirestoreService>().getPostsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(60.0),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'Error loading posts:\n${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final posts = snapshot.data ?? [];
                      
                      if (posts.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No posts yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to post something!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = posts[index];
                            return PostCard(
                              key: ValueKey(post.id), // Stable key prevents AnimationController lifecycle crash on scroll
                              post: post,
                              currentUserId: currentUserId,
                              index: index,
                              onLike: () => _handleLike(post),
                              onComment: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailsScreen(
                                      post: post,
                                      currentUserId: currentUserId,
                                    ),
                                  ),
                                );
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailsScreen(
                                      post: post,
                                      currentUserId: currentUserId,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: posts.length,
                        ),
                      );
                    }
                  ),

                  // Bottom padding so last card isn't hidden by nav bar
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),

      // FAB to create a new post
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreatePostScreen(),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Create Post',
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

// ─── Quick Action Button Widget ───────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
