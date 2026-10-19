// lib/neighbour/screens/community/event_details_screen.dart
//
// Full-page event details screen shown when a user taps "View Details"
// on an event card in the Community / Upcoming Events section.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';

class EventDetailsScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('d MMMM yyyy').format(event.date);
    final timeRange = [event.startTime, event.endTime]
        .where((t) => t.isNotEmpty)
        .join(' – ');

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.darkCard,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                      AppTheme.darkCard,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Text('📅', style: TextStyle(fontSize: 30)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Info chips ────────────────────────────────────────────
                  _InfoCard(children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: dateStr,
                    ),
                    if (timeRange.isNotEmpty) ...[
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: timeRange,
                      ),
                    ],
                    if (event.place.isNotEmpty) ...[
                      const _Divider(),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Venue',
                        value: event.place,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  // ── Description ───────────────────────────────────────────
                  _SectionLabel(label: 'About this event'),
                  const SizedBox(height: 8),
                  _InfoCard(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        event.description.isNotEmpty
                            ? event.description
                            : 'No description provided.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ]),

                  // ── Additional Details ─────────────────────────────────────
                  if (event.additionalDetails.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Additional Details'),
                    const SizedBox(height: 8),
                    _InfoCard(children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event.additionalDetails,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 32),

                  // ── Back button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppTheme.darkBorder, indent: 16, endIndent: 16);
  }
}
