// lib/widgets/post_card.dart
//
// A card widget that displays a single community post in the feed.
// Shows author info, post content, and like/comment counts.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../theme/app_theme.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String? currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;
  final int index; // For staggered animation

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId,
    this.onLike,
    this.onComment,
    this.onTap,
    this.index = 0,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;

  @override
  void initState() {
    super.initState();
    // Controller for the like button bounce animation
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  // Returns a color chip for the post type tag
  Widget _buildTypeChip(BuildContext context) {
    Color chipColor;
    IconData chipIcon;

    switch (widget.post.type) {
      case PostType.helpRequest:
        chipColor = AppTheme.infoColor;
        chipIcon = Icons.handshake_outlined;
        break;
      case PostType.lostFound:
        chipColor = AppTheme.warningColor;
        chipIcon = Icons.search_outlined;
        break;
      case PostType.announcement:
        chipColor = AppTheme.primaryColor;
        chipIcon = Icons.campaign_outlined;
        break;
      case PostType.safety:
        chipColor = AppTheme.errorColor;
        chipIcon = Icons.security_outlined;
        break;
      case PostType.recommendation:
        chipColor = AppTheme.successColor;
        chipIcon = Icons.thumb_up_outlined;
        break;
      default:
        chipColor = AppTheme.grey600;
        chipIcon = Icons.article_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 13, color: chipColor),
          const SizedBox(width: 4),
          Text(
            widget.post.type.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLiked = widget.currentUserId != null &&
        widget.post.likedBy.contains(widget.currentUserId);
    final timeText = timeago.format(widget.post.createdAt);

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Author Row ──────────────────────────────────────────────
              Row(
                children: [
                  // Profile avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                    backgroundImage: widget.post.userPhoto.isNotEmpty
                        ? NetworkImage(widget.post.userPhoto)
                        : null,
                    child: widget.post.userPhoto.isEmpty
                        ? Text(
                            widget.post.userName.isNotEmpty
                                ? widget.post.userName[0].toUpperCase()
                                : 'N',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.userName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          timeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTypeChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // ── Post Content ────────────────────────────────────────────
              Text(
                widget.post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.post.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Post Image (if any) ─────────────────────────────────────
              if (widget.post.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.post.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Actions Row (Like, Comment) ──────────────────────────────
              Row(
                children: [
                  // Like button with animation
                  GestureDetector(
                    onTap: () {
                      // Bounce animation on like
                      _likeController.forward().then((_) {
                        _likeController.reverse();
                      });
                      widget.onLike?.call();
                    },
                    child: AnimatedBuilder(
                      animation: _likeController,
                      builder: (context, child) {
                        // Scale from 1.0 to 1.3 and back on like
                        final scale = 1.0 +
                            0.3 *
                                ((_likeController.value < 0.5)
                                    ? _likeController.value * 2
                                    : (1 - _likeController.value) * 2);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: isLiked
                                ? Colors.red
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.post.likesCount}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Comment button
                  GestureDetector(
                    onTap: widget.onComment,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.post.commentsCount}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        // Animate cards appearing from below with a slight delay per item
        .animate()
        .fadeIn(delay: (50 * widget.index).ms, duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}
