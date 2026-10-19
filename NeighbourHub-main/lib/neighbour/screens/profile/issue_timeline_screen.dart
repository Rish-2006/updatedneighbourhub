// lib/neighbour/screens/profile/issue_timeline_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueTimelineScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final String reportId;

  const IssueTimelineScreen({
    super.key,
    required this.reportData,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISSUE DETAILS'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').doc(reportId).snapshots(),
        builder: (context, snapshot) {
          // Use real-time data if available, else fallback to passed data
          final data = snapshot.hasData && snapshot.data!.exists 
              ? snapshot.data!.data() as Map<String, dynamic> 
              : reportData;

          final title = data['title'] ?? 'No Title';
          final category = data['category'] ?? 'No Category';
          final desc = data['description'] ?? 'No Description';
          final status = data['status'] ?? 'Pending';
          final date = (data['createdAt'] as Timestamp?)?.toDate();
          final dateStr = date != null 
              ? '${date.day} ${_getMonth(date.month)} ${date.year}'
              : 'Unknown Date';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Text('Category:', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(category, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                
                Text('Description:', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(desc, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                
                Text('Submitted:', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                Text(dateStr, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 32),
                
                Text('STATUS', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                _buildTimeline(status, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Widget _buildTimeline(String currentStatus, ThemeData theme) {
    int currentIndex = 0;
    if (currentStatus == 'In Progress') currentIndex = 1;
    if (currentStatus == 'Resolved') currentIndex = 2;

    return Column(
      children: [
        _buildTimelineItem('Submitted', true, true, theme),
        _buildTimelineItem('Pending', currentIndex >= 0, currentIndex == 0, theme),
        _buildTimelineItem('In Progress', currentIndex >= 1, currentIndex == 1, theme),
        _buildTimelineItem('Resolved', currentIndex >= 2, currentIndex == 2, theme, isLast: true),
      ],
    );
  }

  Widget _buildTimelineItem(String text, bool isCompleted, bool isCurrent, ThemeData theme, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isCompleted && !isCurrent ? Icons.check_circle : (isCurrent ? Icons.circle : Icons.radio_button_unchecked),
              color: isCompleted || isCurrent ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? theme.colorScheme.primary : Colors.grey,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCompleted || isCurrent ? theme.colorScheme.onSurface : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
