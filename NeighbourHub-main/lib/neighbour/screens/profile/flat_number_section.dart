// lib/neighbour/screens/profile/flat_number_section.dart
//
// "Your Flat Number" widget — added at the TOP of the existing Profile page.
// Handles selection, submission, pending/verified/rejected states.
// Uses Firestore for data. Checks flat_assignments to prevent duplicates.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

const List<String> _blocks = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

class FlatNumberSection extends StatefulWidget {
  final String userId;
  const FlatNumberSection({super.key, required this.userId});

  @override
  State<FlatNumberSection> createState() => _FlatNumberSectionState();
}

class _FlatNumberSectionState extends State<FlatNumberSection> {
  String? _selectedBlock;
  int? _selectedNumber;
  bool _isSubmitting = false;

  String? get _composedFlat => (_selectedBlock != null && _selectedNumber != null)
      ? '$_selectedBlock$_selectedNumber'
      : null;

  // ── Submit verification request ───────────────────────────────────────────
  Future<void> _submit(String currentStatus) async {
    if (_composedFlat == null) {
      _snack('Please select a block and flat number.', isError: true);
      return;
    }

    final flat = _composedFlat!;
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    final db = FirebaseFirestore.instance;

    try {
      // 1. Check if flat is currently pending by another user
      final pendingSnap = await db
          .collection('flat_verification_requests')
          .where('flatNumber', isEqualTo: flat)
          .where('status', isEqualTo: 'Pending')
          .get();

      final takenByOther = pendingSnap.docs
          .any((d) => (d.data()['userId'] as String? ?? '') != user.uid);

      if (takenByOther) {
        _snack('Flat $flat is already pending for another user. Choose a different flat.', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // 2. Check if flat is permanently assigned
      final assignSnap =
          await db.collection('flat_assignments').doc(flat).get();
      if (assignSnap.exists) {
        final existingUid = assignSnap.data()?['userId'] as String? ?? '';
        if (existingUid != user.uid) {
          _snack('Flat $flat is already verified and assigned to another resident.', isError: true);
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // 3. Get user display info
      final userDoc = await db.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] as String? ??
          user.displayName ??
          'User';
      final userEmail = user.email ?? '';

      // 4. Create / update verification request
      final existingReqs = await db
          .collection('flat_verification_requests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Pending')
          .get();

      final batch = db.batch();

      // Cancel previous pending request if it exists
      for (final doc in existingReqs.docs) {
        batch.update(doc.reference, {'status': 'Cancelled'});
      }

      final reqRef = db.collection('flat_verification_requests').doc();
      batch.set(reqRef, {
        'userId': user.uid,
        'userName': userName,
        'userEmail': userEmail,
        'flatNumber': flat,
        'status': 'Pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Update user document
      batch.update(db.collection('users').doc(user.uid), {
        'flatNumber': flat,
        'flatVerificationStatus': 'Pending',
        'flatVerificationRequestedAt': FieldValue.serverTimestamp(),
      });

      // Notify admin via notifications collection
      final adminSnap = await db
          .collection('users')
          .where('email', isEqualTo: 'srimadhu6521@gmail.com')
          .get();

      String adminId = 'admin'; // fallback
      if (adminSnap.docs.isNotEmpty) {
        adminId = adminSnap.docs.first.id;
      }

      final notifRef = db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': adminId,
        'title': 'Flat Verification Request 🏠',
        'message': '$userName has requested verification for flat $flat.',
        'type': 'flatVerificationRequest',
        'requestId': reqRef.id,
        'requestedFlat': flat,
        'requestingUserId': user.uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      _snack('Verification request submitted for flat $flat!');
    } catch (e) {
      _snack('Submission failed: $e', isError: true);
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final flatNumber = data['flatNumber'] as String? ?? '';
        final status = data['flatVerificationStatus'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section title ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.home_work_outlined,
                        size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR FLAT NUMBER',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _borderColor(status),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(theme, flatNumber, status),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  Color _borderColor(String status) {
    switch (status) {
      case 'Verified': return AppTheme.successColor.withValues(alpha: 0.5);
      case 'Pending':  return AppTheme.warningColor.withValues(alpha: 0.5);
      case 'Rejected': return AppTheme.errorColor.withValues(alpha: 0.5);
      default:         return AppTheme.darkBorder;
    }
  }

  Widget _buildContent(ThemeData theme, String flatNumber, String status) {
    // ── VERIFIED ──────────────────────────────────────────────────────────────
    if (status == 'Verified' && flatNumber.isNotEmpty) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              flatNumber,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('🟢', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your flat is confirmed.',
                  style: TextStyle(fontSize: 12, color: AppTheme.darkSubtext),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── PENDING ───────────────────────────────────────────────────────────────
    if (status == 'Pending' && flatNumber.isNotEmpty) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              flatNumber,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('🟡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'Verification Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Admin review in progress.',
                  style: TextStyle(fontSize: 12, color: AppTheme.darkSubtext),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── REJECTED ──────────────────────────────────────────────────────────────
    if (status == 'Rejected') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (flatNumber.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    flatNumber,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(children: [
                        Text('🔴', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text('Verification Rejected',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorColor,
                            fontSize: 13,
                          )),
                      ]),
                      SizedBox(height: 2),
                      Text('Select another flat and try again.',
                          style: TextStyle(fontSize: 12, color: AppTheme.darkSubtext)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          _buildSelector(),
          const SizedBox(height: 12),
          _buildSubmitButton('SUBMIT AGAIN'),
        ],
      );
    }

    // ── DEFAULT (no flat yet) ─────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'No flat number added yet.',
          style: TextStyle(color: AppTheme.darkSubtext, fontSize: 13),
        ),
        const SizedBox(height: 14),
        _buildSelector(),
        const SizedBox(height: 12),
        _buildSubmitButton('SUBMIT FOR VERIFICATION'),
      ],
    );
  }

  // ── Dropdown selectors ──────────────────────────────────────────────────────
  Widget _buildSelector() {
    return Row(
      children: [
        // Block dropdown
        Expanded(
          child: _Dropdown<String>(
            label: 'Block',
            value: _selectedBlock,
            items: _blocks,
            itemLabel: (b) => 'Block $b',
            onChanged: (v) => setState(() => _selectedBlock = v),
          ),
        ),
        const SizedBox(width: 10),
        // Number dropdown
        Expanded(
          child: _Dropdown<int>(
            label: 'Flat No.',
            value: _selectedNumber,
            items: List.generate(30, (i) => i + 1),
            itemLabel: (n) => '$n',
            onChanged: (v) => setState(() => _selectedNumber = v),
          ),
        ),
        // Preview
        if (_composedFlat != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _composedFlat!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppTheme.primaryColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : () => _submit(''),
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.send_rounded, size: 16),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size.zero,
        ),
      ),
    );
  }
}

// ─── Generic Dropdown ─────────────────────────────────────────────────────────
class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSubtext,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.darkCard,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              hint: Text(
                'Select',
                style: TextStyle(
                    color: AppTheme.darkSubtext.withValues(alpha: 0.6),
                    fontSize: 13),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.darkSubtext),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
