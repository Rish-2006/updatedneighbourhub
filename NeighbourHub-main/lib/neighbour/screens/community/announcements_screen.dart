// lib/screens/community/announcements_screen.dart
//
// Full list of community announcements — loaded live from Firestore.
// Admin creates via Admin Dashboard → Announcements.
// All authenticated users can read.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ── Error ────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppTheme.errorColor),
                  SizedBox(height: 12),
                  Text('Could not load announcements.',
                      style: TextStyle(color: AppTheme.darkSubtext)),
                ],
              ),
            );
          }

          // ── Loading ──────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // ── Empty ────────────────────────────────────────────────────────
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64,
                      color: AppTheme.darkSubtext.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No announcements available.',
                    style: TextStyle(color: AppTheme.darkSubtext, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // ── List ─────────────────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              final description = data['description'] as String? ?? '';
              final createdBy = data['createdBy'] as String? ?? 'Admin';
              final imageUrl = data['imageUrl'] as String? ?? '';

              // Format date from Firestore Timestamp
              String dateStr = 'Recently';
              final ts = data['createdAt'];
              if (ts is Timestamp) {
                final dt = ts.toDate();
                dateStr = '${dt.day} ${_monthName(dt.month)} ${dt.year}';
              }

              return Card(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Optional image
                      if (imageUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Official badge
                      Row(
                        children: [
                          const Icon(Icons.campaign,
                              color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'OFFICIAL ANNOUNCEMENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Footer
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            createdBy,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.grey600),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppTheme.grey600),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.grey600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }
}
