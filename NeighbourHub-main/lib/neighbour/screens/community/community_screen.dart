// lib/screens/community/community_screen.dart
//
// Community hub screen with announcements, events preview, rules, services, safety info.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../data/mock_data.dart';
import '../../widgets/event_card.dart';
import 'events_screen.dart';
import 'announcements_screen.dart';
import '../lost_found/lost_found_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Announcements Section ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.campaign_outlined,
            title: 'Announcements',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Latest announcement — live from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final data =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              return _AnnouncementPreviewCard(
                title: data['title'] as String? ?? '',
                message: data['description'] as String? ?? '',
                postedBy: data['createdBy'] as String? ?? 'Admin',
              ).animate().fadeIn(delay: 100.ms);
            },
          ),

          const SizedBox(height: 8),

          // ── Upcoming Events Section ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.event_outlined,
            title: 'Upcoming Events',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsScreen()),
            ),
          ).animate().fadeIn(delay: 150.ms),

          // Show first 2 upcoming events — live from Firestore
          StreamBuilder<List<EventModel>>(
            stream: context.read<FirestoreService>().getUpcomingEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              final events = (snapshot.data ?? []).take(2).toList();

              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: const Column(
                      children: [
                        Text('📅', style: TextStyle(fontSize: 28)),
                        SizedBox(height: 8),
                        Text(
                          'No upcoming events',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'New community events will appear here\nwhen they are announced.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.darkSubtext, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: events.asMap().entries.map((entry) {
                  return EventCard(
                    event: entry.value,
                    index: entry.key,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Lost & Found shortcut ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _CommunityTile(
              icon: Icons.search_outlined,
              iconColor: AppTheme.warningColor,
              title: 'Lost & Found',
              subtitle: 'Report lost items or claim found ones',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LostFoundScreen()),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),


          // ── Community Rules ──────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.rule_outlined,
            title: 'Community Rules',
            onViewAll: null,
          ).animate().fadeIn(delay: 400.ms),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: MockData.communityRules
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 450.ms),

          // ── Safety Information ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _CommunityTile(
              icon: Icons.security_outlined,
              iconColor: AppTheme.errorColor,
              title: 'Safety & Emergency',
              subtitle: 'Emergency contacts and safety guidelines',
              onTap: () => Navigator.pushNamed(context, '/emergency'),
            ),
          ).animate().fadeIn(delay: 500.ms),


        ],
      ),
    );
  }
}

// ─── Section Header Widget ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

// ─── Announcement Preview Card ────────────────────────────────────────────────
class _AnnouncementPreviewCard extends StatelessWidget {
  final String title;
  final String message;
  final String postedBy;

  const _AnnouncementPreviewCard({
    required this.title,
    required this.message,
    required this.postedBy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'COMMUNITY ANNOUNCEMENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'By $postedBy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Community Tile ────────────────────────────────────────────────────────────
class _CommunityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CommunityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

