// lib/neighbour/screens/profile/my_issues_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'issue_timeline_screen.dart';

class MyIssuesScreen extends StatelessWidget {
  const MyIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Issue Status')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY ISSUE STATUS'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          // Sort client-side newest first — avoids needing a composite index
          docs.sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as dynamic).compareTo(aTs as dynamic);
          });

          if (docs.isEmpty) {
            return const Center(child: Text('You have not reported any issues.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final title = data['title'] ?? 'No Title';
              final category = data['category'] ?? 'No Category';
              final desc = data['description'] ?? 'No Description';
              final status = data['status'] ?? 'Pending';
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final dateStr = date != null 
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(category, style: TextStyle(color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text('Submitted: $dateStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: _buildStatusIndicator(status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IssueTimelineScreen(
                          reportData: data,
                          reportId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'Pending':
        color = Colors.red;
        icon = Icons.circle;
        break;
      case 'In Progress':
        color = Colors.orange;
        icon = Icons.circle;
        break;
      case 'Resolved':
        color = Colors.green;
        icon = Icons.circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle;
    }
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
