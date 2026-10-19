// lib/screens/posts/create_post_screen.dart
//
// Screen for creating a new community post.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  // Callback to add the new post to the parent's list
  final void Function(PostModel post)? onPostCreated;

  const CreatePostScreen({super.key, this.onPostCreated});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PostType _selectedType = PostType.general;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPosting = true);

    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      setState(() => _isPosting = false);
      return;
    }

    // Create the new post
    final newPost = PostModel(
      id: const Uuid().v4(), // Generate a unique ID
      userId: user.uid,
      userName: user.displayName ?? 'Neighbour',
      userPhoto: user.photoURL ?? '',
      type: _selectedType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await context.read<FirestoreService>().createPost(newPost);
      
      if (!mounted) return;
      
      // Notify parent and close screen
      widget.onPostCreated?.call(newPost);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Post created successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating post: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting ? null : _createPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width > 600 ? size.width * 0.15 : 16,
          vertical: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Post Type Selector ─────────────────────────────────────
              Text(
                'Post Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 10),

              // Horizontal scrollable chips for post type
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PostType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedType = type);
                        },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────────
              Text(
                'Title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'e.g. Looking for a good plumber',
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title is too short';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // ── Description ────────────────────────────────────────────
              Text(
                'Description',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Share more details with your neighbours...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description is too short';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // ── Post Button ────────────────────────────────────────────
              ElevatedButton(
                onPressed: _isPosting ? null : _createPost,
                child: _isPosting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : const Text('Post to Community'),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
