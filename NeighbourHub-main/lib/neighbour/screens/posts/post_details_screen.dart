// lib/screens/posts/post_details_screen.dart
//
// Full detail view for a single post, showing comments section.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class PostDetailsScreen extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;

  const PostDetailsScreen({
    super.key,
    required this.post,
    this.currentUserId,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final comment = CommentModel(
      id: const Uuid().v4(),
      postId: widget.post.id,
      authorId: user.uid,
      authorName: user.displayName ?? 'Neighbour',
      authorPhoto: user.photoURL ?? '',
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<FirestoreService>().addComment(comment);
      _commentController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          // Post content + comments
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Post Card ─────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                              child: Text(
                                post.userName.isNotEmpty
                                    ? post.userName[0].toUpperCase()
                                    : 'N',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.userName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  timeago.format(post.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          post.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.favorite_border,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('${post.likesCount}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.chat_bubble_outline, size: 18),
                            const SizedBox(width: 4),
                            StreamBuilder<List<CommentModel>>(
                              stream: context.read<FirestoreService>().getCommentsStream(post.id),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.length ?? post.commentsCount;
                                return Text('$count comments');
                              }
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 16),

                // ── Comments ──────────────────────────────────────────────
                Text(
                  'Comments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                StreamBuilder<List<CommentModel>>(
                  stream: context.read<FirestoreService>().getCommentsStream(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    
                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: comments.asMap().entries.map((entry) {
                        final c = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppTheme.primaryColor.withValues(alpha: 0.15),
                                child: Text(
                                  c.authorName.isNotEmpty
                                      ? c.authorName[0].toUpperCase()
                                      : 'N',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w700),
                                          ),
                                          const Spacer(),
                                          Text(
                                            timeago.format(c.createdAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme.colorScheme.onSurface
                                                        .withValues(alpha: 0.4),
                                                    fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.text,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (entry.key * 50).ms);
                      }).toList(),
                    );
                  }
                ),
              ],
            ),
          ),

          // ── Comment Input ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _isSubmitting ? null : _addComment,
                  icon: _isSubmitting 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  color: AppTheme.primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
