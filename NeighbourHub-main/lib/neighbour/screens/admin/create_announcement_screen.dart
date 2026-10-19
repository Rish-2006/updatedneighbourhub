// lib/neighbour/screens/admin/create_announcement_screen.dart
//
// Admin-only screen to compose and publish a community announcement.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isPosting = true);

    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': '',
        'createdBy': user?.displayName ?? 'Admin',
        'createdByEmail': user?.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Announcement posted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      _showError('Firestore error: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      _showError('Failed to post announcement. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: AppTheme.darkBg,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 13, color: AppTheme.primaryColor),
                  SizedBox(width: 4),
                  Text('Admin Only',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero banner ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign,
                          color: AppTheme.primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Announcement',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            'This will be visible to all community members.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkSubtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 28),

              // ── Title ───────────────────────────────────────────────────────
              _FieldLabel(label: 'TITLE', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'e.g. Community Meeting on Saturday',
                  counterStyle: TextStyle(color: AppTheme.darkSubtext),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required.';
                  }
                  if (v.trim().length < 5) {
                    return 'Title must be at least 5 characters.';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Description ─────────────────────────────────────────────────
              _FieldLabel(label: 'DESCRIPTION', required: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText:
                      'Write the full announcement details here…\n\nInclude any important dates, locations, or instructions.',
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(color: AppTheme.darkSubtext),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Description is required.';
                  }
                  if (v.trim().length < 10) {
                    return 'Description must be at least 10 characters.';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Optional image placeholder ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.darkBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.image_outlined,
                        color: AppTheme.darkSubtext, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Image (Optional)',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.darkSubtext),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Image upload can be added later via Firebase Storage.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.darkSubtext),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // ── Post button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isPosting ? null : _postAnnouncement,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isPosting ? 'Posting…' : 'POST ANNOUNCEMENT',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppTheme.darkSubtext,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.errorColor,
              )),
        ],
      ],
    );
  }
}
