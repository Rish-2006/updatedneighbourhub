// lib/neighbour/screens/admin/admin_report_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportDetailsScreen extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const AdminReportDetailsScreen({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<AdminReportDetailsScreen> createState() => _AdminReportDetailsScreenState();
}

class _AdminReportDetailsScreenState extends State<AdminReportDetailsScreen> {
  late String _status;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.reportData['status'] ?? 'Pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    final oldStatus = _status;
    if (oldStatus == newStatus) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final reportRef = FirebaseFirestore.instance.collection('reports').doc(widget.reportId);
      
      batch.update(reportRef, {'status': newStatus});
      
      // Create notification
      final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': widget.reportData['userId'],
        'title': 'Issue ${newStatus == "Resolved" ? "Resolved" : "Update"}',
        'message': 'Your reported issue \'${widget.reportData['title']}\' is now $newStatus.',
        'type': 'issueStatus',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'reportId': widget.reportId,
        'status': newStatus,
      });
      
      await batch.commit();

      if (!mounted) return;
      setState(() {
        _status = newStatus;
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.reportData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${data['title'] ?? 'No Title'}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Category: ${data['category'] ?? 'N/A'}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['description'] ?? 'No description provided.'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text('Reporter Name: ${data['userName'] ?? 'Unknown'}'),
            Text('Reporter Email: ${data['userEmail'] ?? 'Unknown'}'),
            Text('User ID: ${data['userId'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Submitted At: ${(data['createdAt'] as Timestamp?)?.toDate().toString() ?? 'Unknown'}'),
            const SizedBox(height: 16),
            if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
              const Text('Attachment:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.network(data['imageUrl']),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 16),
            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _status,
              isExpanded: true,
              items: ['Pending', 'In Progress', 'Resolved'].map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s),
                );
              }).toList(),
              onChanged: _isUpdating ? null : (newValue) {
                if (newValue != null && newValue != _status) {
                  _updateStatus(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
