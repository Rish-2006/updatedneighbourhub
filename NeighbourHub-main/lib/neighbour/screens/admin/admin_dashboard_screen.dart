// lib/neighbour/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'admin_report_details_screen.dart';
import 'create_announcement_screen.dart';
import 'flat_verification_screen.dart';
import 'admin_users_screen.dart';
import 'admin_events_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.report_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Reports'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.campaign_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Announcements'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home_work_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Flats'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.manage_accounts_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Users'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.event_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Events'),
                ],
              ),
            ),
          ],
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.darkSubtext,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Reports ─────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterRow(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading reports.'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    final filteredDocs = _filter == 'All'
                        ? docs
                        : docs
                            .where((doc) => doc.get('status') == _filter)
                            .toList();
                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text('No reports found.'));
                    }
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(data['title'] ?? 'No Title'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['category'] ?? 'No Category'),
                                Text(
                                    'By: ${data['userName'] ?? 'Unknown'} (${data['userEmail'] ?? 'Unknown'})'),
                              ],
                            ),
                            trailing: _buildStatusChip(data['status'] ?? 'Pending'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminReportDetailsScreen(
                                  reportId: doc.id,
                                  reportData: data,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Tab 2: Announcements ───────────────────────────────────────────
          _AnnouncementsTab(),

          // ── Tab 3: Flat Verification ───────────────────────────────────────
          const FlatVerificationScreen(),

          // ── Tab 4: User Management ────────────────────────────────────────
          const AdminUsersScreen(),

          // ── Tab 5: Events ─────────────────────────────────────────────────
          const AdminEventsScreen(),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: ['All', 'Pending', 'In Progress', 'Resolved'].map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(status),
              selected: _filter == status,
              onSelected: (selected) {
                if (selected) setState(() => _filter = status);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':     color = Colors.orange; break;
      case 'In Progress': color = Colors.blue;   break;
      case 'Resolved':    color = Colors.green;  break;
      default:            color = Colors.grey;
    }
    return Chip(
      label: Text(status,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}

// ─── Announcements Tab ─────────────────────────────────────────────────────────
class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab();

  Future<void> _deleteAnnouncement(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Delete Announcement',
            style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppTheme.darkSubtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(id)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement deleted.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create Announcement'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.errorColor)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 60,
                      color:
                          AppTheme.darkSubtext.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No announcements yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.darkSubtext)),
                  const SizedBox(height: 4),
                  Text('Tap + to create one.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.darkSubtext.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              final description = data['description'] as String? ?? '';
              final createdBy = data['createdBy'] as String? ?? 'Admin';
              final ts = data['createdAt'];
              String dateStr = 'Recently';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                dateStr =
                    '${dt.day} ${_monthName(dt.month)} ${dt.year}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.campaign,
                                    color: AppTheme.primaryColor, size: 12),
                                SizedBox(width: 4),
                                Text('ANNOUNCEMENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryColor,
                                    )),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Delete button
                          IconButton(
                            onPressed: () =>
                                _deleteAnnouncement(context, doc.id),
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.errorColor, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(description,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.darkSubtext, height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 13, color: AppTheme.darkSubtext),
                          const SizedBox(width: 4),
                          Text(createdBy,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.darkSubtext)),
                          const Spacer(),
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppTheme.darkSubtext),
                          const SizedBox(width: 4),
                          Text(dateStr,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.darkSubtext)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
