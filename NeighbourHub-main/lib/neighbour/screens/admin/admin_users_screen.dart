// lib/neighbour/screens/admin/admin_users_screen.dart
//
// Admin-only User Management screen.
// Lists all normal users (excludes admin), supports search, and allows deletion.
//
// IMPORTANT — Firebase Auth deletion:
// A Flutter client cannot delete another user's Firebase Auth account directly.
// This screen deletes ALL Firestore data for the user and relies on a
// Cloud Function (triggered by Firestore document deletion or via callable)
// to complete Auth account removal.  If no Cloud Function exists yet, the
// Firestore data is fully cleaned up here and a comment marks where to add
// the callable invocation once the function is deployed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Admin email — never show a Delete button for this account
  static const String _adminEmail = AppConstants.adminEmail;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (_searchCtrl.text != _query) {
        setState(() => _query = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Deletion logic ────────────────────────────────────────────────────────

  /// Deletes ALL Firestore data belonging to the user.
  /// Collections cleaned: users, flat_assignments, flat_verification_requests,
  /// connections, connection_requests, notifications, posts.
  Future<void> _deleteUserData(String uid, String? flatNumber) async {
    final batch = _db.batch();

    // 1. Delete user profile document
    batch.delete(_db.collection('users').doc(uid));

    // 2. Release flat assignment if the user had a verified flat
    if (flatNumber != null && flatNumber.isNotEmpty) {
      final assignRef = _db.collection('flat_assignments').doc(flatNumber);
      final assignSnap = await assignRef.get();
      if (assignSnap.exists && assignSnap.data()?['userId'] == uid) {
        batch.delete(assignRef);
      }
    }

    await batch.commit();

    // 3. Delete flat verification requests for this user (may be multiple)
    final fvrSnap = await _db
        .collection('flat_verification_requests')
        .where('userId', isEqualTo: uid)
        .get();
    if (fvrSnap.docs.isNotEmpty) {
      final fvrBatch = _db.batch();
      for (final doc in fvrSnap.docs) {
        fvrBatch.delete(doc.reference);
      }
      await fvrBatch.commit();
    }

    // 4. Delete connection documents where this user is user1Id or user2Id
    final connSnap1 = await _db
        .collection('connections')
        .where('user1Id', isEqualTo: uid)
        .get();
    final connSnap2 = await _db
        .collection('connections')
        .where('user2Id', isEqualTo: uid)
        .get();
    if (connSnap1.docs.isNotEmpty || connSnap2.docs.isNotEmpty) {
      final connBatch = _db.batch();
      for (final doc in [...connSnap1.docs, ...connSnap2.docs]) {
        connBatch.delete(doc.reference);
      }
      await connBatch.commit();
    }

    // 5. Delete connection requests sent or received by this user
    final crSentSnap = await _db
        .collection('connection_requests')
        .where('senderId', isEqualTo: uid)
        .get();
    final crRecvSnap = await _db
        .collection('connection_requests')
        .where('receiverId', isEqualTo: uid)
        .get();
    if (crSentSnap.docs.isNotEmpty || crRecvSnap.docs.isNotEmpty) {
      final crBatch = _db.batch();
      for (final doc in [...crSentSnap.docs, ...crRecvSnap.docs]) {
        crBatch.delete(doc.reference);
      }
      await crBatch.commit();
    }

    // 6. Delete notifications belonging to this user only
    final notifSnap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .get();
    if (notifSnap.docs.isNotEmpty) {
      final notifBatch = _db.batch();
      for (final doc in notifSnap.docs) {
        notifBatch.delete(doc.reference);
      }
      await notifBatch.commit();
    }

    // 7. Delete posts created by this user
    final postsSnap = await _db
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .get();
    if (postsSnap.docs.isNotEmpty) {
      final postsBatch = _db.batch();
      for (final doc in postsSnap.docs) {
        postsBatch.delete(doc.reference);
      }
      await postsBatch.commit();
    }

    // NOTE: Firebase Auth account deletion requires Admin SDK (server-side).
    // If you deploy a Cloud Function named "deleteUser" that accepts {uid},
    // uncomment and call it here:
    //
    // final functions = FirebaseFunctions.instance;
    // await functions.httpsCallable('deleteUser').call({'uid': uid});
    //
    // Without this, the Firestore data is fully removed but the Auth entry
    // remains until the user tries to log in again (login will fail without data).
  }

  /// Full delete flow with confirmation dialog.
  Future<void> _confirmAndDelete(
    BuildContext context,
    String uid,
    String name,
    String? flatNumber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppTheme.darkSubtext, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(
                  text: 'Are you sure you want to permanently delete:\n\n'),
              TextSpan(
                text: name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const TextSpan(
                text:
                    '\n\nThis will remove the user\'s profile, flat assignment, connections, and all associated data. This action cannot be undone.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.darkSubtext,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Deleting account…'),
          ],
        ),
        duration: Duration(seconds: 10),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await _deleteUserData(uid, flatNumber);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully. ($name)'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete this account. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        if (snap.hasError) {
          return const Center(
            child: Text(
              'Error loading users.',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        // Exclude admin from the list
        final allDocs = (snap.data?.docs ?? [])
            .where((d) {
              final email = (d.data() as Map<String, dynamic>)['email']
                  as String? ??
                  '';
              return email.toLowerCase() != _adminEmail.toLowerCase();
            })
            .toList();

        // Apply search filter
        final filtered = _query.isEmpty
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name =
                    (data['name'] as String? ?? '').toLowerCase();
                final email =
                    (data['email'] as String? ?? '').toLowerCase();
                final flat =
                    (data['flatNumber'] as String? ?? '').toLowerCase();
                final apartment =
                    (data['apartment'] as String? ?? '').toLowerCase();
                return name.contains(_query) ||
                    email.contains(_query) ||
                    flat.contains(_query) ||
                    apartment.contains(_query);
              }).toList();

        return Column(
          children: [
            // ── Stats + Search ─────────────────────────────────────────
            Container(
              color: AppTheme.darkBg,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Total Users card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Users',
                              style: TextStyle(
                                color: AppTheme.darkSubtext,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${allDocs.length}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_query.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      AppTheme.infoColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${filtered.length} results',
                              style: const TextStyle(
                                color: AppTheme.infoColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search bar
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search users by name, email or flat…',
                      hintStyle: const TextStyle(color: AppTheme.darkSubtext),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primaryColor),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppTheme.darkSubtext),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // ── User List ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(query: _query)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = filtered[index];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return _UserCard(
                          uid: doc.id,
                          data: data,
                          onDelete: (uid, name, flatNumber) =>
                              _confirmAndDelete(
                                  context, uid, name, flatNumber),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── User Card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final Future<void> Function(String uid, String name, String? flatNumber)
      onDelete;

  const _UserCard({
    required this.uid,
    required this.data,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unknown';
    final email = data['email'] as String? ?? '';

    // Flat info — support both 'flatNumber' (new) and 'apartment' (legacy)
    final flatNumber = _nonEmpty(data['flatNumber'] as String?) ??
        _nonEmpty(data['apartment'] as String?);
    final verificationStatus =
        data['flatVerificationStatus'] as String? ?? '';

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: avatar + name + email ────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppTheme.darkSubtext,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppTheme.darkBorder, height: 1),
            const SizedBox(height: 12),

            // ── Flat + verification status ────────────────────────────
            if (flatNumber != null && flatNumber.isNotEmpty)
              _FlatStatus(
                  flatNumber: flatNumber,
                  verificationStatus: verificationStatus)
            else
              Row(
                children: [
                  Icon(Icons.home_outlined,
                      size: 14,
                      color: AppTheme.darkSubtext.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'No flat assigned',
                    style: TextStyle(
                      color: AppTheme.darkSubtext.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 14),

            // ── Delete button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onDelete(uid, name, flatNumber),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorColor, size: 16),
                label: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppTheme.errorColor.withValues(alpha: 0.5)),
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _nonEmpty(String? s) =>
      (s == null || s.isEmpty || s == 'null') ? null : s;
}

// ─── Flat Status Badge ─────────────────────────────────────────────────────────
class _FlatStatus extends StatelessWidget {
  final String flatNumber;
  final String verificationStatus;

  const _FlatStatus({
    required this.flatNumber,
    required this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (verificationStatus) {
      case 'Verified':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.verified_rounded;
        statusLabel = 'Verified';
        break;
      case 'Pending':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending_outlined;
        statusLabel = 'Pending';
        break;
      case 'Rejected':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Rejected';
        break;
      default:
        // Has a flat but no verification status yet
        statusColor = AppTheme.darkSubtext;
        statusIcon = Icons.home_outlined;
        statusLabel = '';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.home_outlined, size: 14, color: AppTheme.darkSubtext),
        const SizedBox(width: 6),
        Text(
          'Flat $flatNumber',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (statusLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            query.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            size: 64,
            color: AppTheme.darkSubtext.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            query.isNotEmpty
                ? 'No users match "$query"'
                : 'No users registered yet.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            query.isNotEmpty
                ? 'Try a different name, email, or flat number.'
                : 'Users will appear here after they register.',
            style: const TextStyle(
                color: AppTheme.darkSubtext, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
