// lib/neighbour/screens/profile/my_posts_screen.dart
//
// Shows only the posts created by the currently logged-in user.
// Reuses the existing PostCard widget and FirestoreService stream.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../posts/post_details_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    // Safety check — should never happen since user must be logged in to reach here
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Posts')),
        body: const Center(child: Text('Please log in to see your posts.')),
      );
    }

    final currentUserId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: context.read<FirestoreService>().getUserPostsStream(currentUserId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state — log the real error to debug console
          if (snapshot.hasError) {
            debugPrint('══════ MyPostsScreen error ══════');
            debugPrint('Collection : posts');
            debugPrint('Filter     : userId == $currentUserId');
            debugPrint('Error      : ${snapshot.error}');
            debugPrint('StackTrace : ${snapshot.stackTrace}');
            debugPrint('═════════════════════════════════');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load your posts.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final posts = snapshot.data ?? [];

          // Empty state
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "You haven't posted anything yet.",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share something with your community!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            );
          }

          // Post list — reuses the exact same PostCard from the community feed
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                currentUserId: currentUserId,
                index: index,
                onLike: () {
                  context.read<FirestoreService>().toggleLike(post.id, currentUserId);
                },
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
          );
        },
      ),
    );
  }
}
