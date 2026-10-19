// lib/neighbour/screens/admin/flat_verification_screen.dart
//
// Admin screen to view, approve, and reject flat verification requests.
// Uses Firestore transactions to enforce uniqueness (one flat per account).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class FlatVerificationScreen extends StatelessWidget {
  const FlatVerificationScreen({super.key});

  // ── Approve with atomic transaction ──────────────────────────────────────────
  Future<void> _approveClaim(BuildContext context, String requestId,
      Map<String, dynamic> data) async {
    final db = FirebaseFirestore.instance;
    final flatNumber = data['flatNumber'] as String;
    final userId = data['userId'] as String;
    final userName = data['userName'] as String? ?? 'User';

    try {
      await db.runTransaction((tx) async {
        final assignRef = db.collection('flat_assignments').doc(flatNumber);
        final assignSnap = await tx.get(assignRef);

        // Check if flat is already assigned to another user
        if (assignSnap.exists) {
          final existingUserId = assignSnap.data()?['userId'] as String?;
          if (existingUserId != null && existingUserId != userId) {
            throw Exception(
                'Flat $flatNumber is already assigned to another resident.');
          }
        }

        final reqRef = db.collection('flat_verification_requests').doc(requestId);
        final reqSnap = await tx.get(reqRef);
        if (!reqSnap.exists) throw Exception('Request not found.');
        if ((reqSnap.data()?['status'] as String?) != 'Pending') {
          throw Exception('This request has already been processed.');
        }

        final userRef = db.collection('users').doc(userId);

        // Assign the flat
        tx.set(assignRef, {
          'userId': userId,
          'userName': userName,
          'flatNumber': flatNumber,
          'assignedAt': FieldValue.serverTimestamp(),
          'status': 'assigned',
        });

        // Update the verification request
        tx.update(reqRef, {
          'status': 'Approved',
          'processedAt': FieldValue.serverTimestamp(),
        });

        // Update the user document
        tx.update(userRef, {
          'flatNumber': flatNumber,
          'flatVerificationStatus': 'Verified',
          'flatVerifiedAt': FieldValue.serverTimestamp(),
        });

        // Notify the user
        final notifRef = db.collection('notifications').doc();
        tx.set(notifRef, {
          'userId': userId,
          'title': 'Flat Verified ✅',
          'message': 'Your flat $flatNumber has been verified successfully.',
          'type': 'flatVerification',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Flat approved and verified!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('This request has already been processed.')) {
        // Silently ignore if already processed to prevent duplicate error messages.
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: ${errorMsg.replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────────
  Future<void> _rejectClaim(BuildContext context, String requestId,
      Map<String, dynamic> data) async {
    final db = FirebaseFirestore.instance;
    final flatNumber = data['flatNumber'] as String;
    final userId = data['userId'] as String;

    try {
      final batch = db.batch();

      batch.update(db.collection('flat_verification_requests').doc(requestId), {
        'status': 'Rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      batch.update(db.collection('users').doc(userId), {
        'flatVerificationStatus': 'Rejected',
      });

      final notifRef = db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': userId,
        'title': 'Flat Verification Update',
        'message': 'Your flat $flatNumber could not be verified. You may submit another request.',
        'type': 'flatVerification',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reject failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flat_verification_requests')
          .orderBy('requestedAt', descending: false)
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

        final allDocs = snapshot.data?.docs ?? [];
        final pendingDocs =
            allDocs.where((d) => (d.data() as Map)['status'] == 'Pending').toList();
        final processedDocs =
            allDocs.where((d) => (d.data() as Map)['status'] != 'Pending').toList();

        if (allDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 60,
                    color: AppTheme.darkSubtext.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No flat verification requests.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.darkSubtext)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Pending section ──────────────────────────────────────────────
            if (pendingDocs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.warningColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PENDING REQUESTS (${pendingDocs.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
              ...pendingDocs.asMap().entries.map((e) {
                final doc = e.value;
                final data = doc.data() as Map<String, dynamic>;
                return _RequestCard(
                  key: ValueKey(doc.id),
                  data: data,
                  requestId: doc.id,
                  isPending: true,
                  index: e.key,
                  onApprove: () => _approveClaim(context, doc.id, data),
                  onReject: () => _rejectClaim(context, doc.id, data),
                );
              }),
              const SizedBox(height: 16),
            ],

            // ── Processed section ────────────────────────────────────────────
            if (processedDocs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'PROCESSED',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.darkSubtext,
                  ),
                ),
              ),
              ...processedDocs.asMap().entries.map((e) {
                final doc = e.value;
                final data = doc.data() as Map<String, dynamic>;
                return _RequestCard(
                  key: ValueKey(doc.id),
                  data: data,
                  requestId: doc.id,
                  isPending: false,
                  index: e.key,
                  onApprove: null,
                  onReject: null,
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

// ─── Request Card ──────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final bool isPending;
  final int index;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({
    super.key,
    required this.data,
    required this.requestId,
    required this.isPending,
    required this.index,
    required this.onApprove,
    required this.onReject,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':  return AppTheme.warningColor;
      case 'Approved': return AppTheme.successColor;
      case 'Rejected': return AppTheme.errorColor;
      default:         return AppTheme.darkSubtext;
    }
  }

  String _statusEmoji(String s) {
    switch (s) {
      case 'Pending':  return '🟡';
      case 'Approved': return '🟢';
      case 'Rejected': return '🔴';
      default:         return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flatNumber = data['flatNumber'] as String? ?? '—';
    final userName = data['userName'] as String? ?? 'Unknown';
    final userEmail = data['userEmail'] as String? ?? '';
    final status = data['status'] as String? ?? 'Pending';
    final ts = data['requestedAt'];
    String dateStr = 'Recently';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPending
              ? AppTheme.warningColor.withValues(alpha: 0.35)
              : AppTheme.darkBorder,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (userEmail.isNotEmpty)
                        Text(userEmail,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.darkSubtext),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_statusEmoji(status)} $status',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Flat info ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_work_outlined,
                      color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Requested Flat',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.darkSubtext)),
                      Text(flatNumber,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Requested',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.darkSubtext)),
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.darkSubtext)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Approve / Reject buttons ─────────────────────────────────────
            if (isPending && onApprove != null && onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
  }
}
