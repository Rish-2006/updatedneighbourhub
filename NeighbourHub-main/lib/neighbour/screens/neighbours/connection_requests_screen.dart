// lib/screens/neighbours/connection_requests_screen.dart
//
// Premium connection requests screen with accept/decline actions,
// grouped by date, and unread indicator.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/connection_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userId = authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text(
          'Connection Requests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ConnectionRequestModel>>(
        stream: firestoreService.getPendingRequestsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return _ErrorView();
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _EmptyRequests();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final req = requests[index];
              return _RequestCard(
                request: req,
                firestoreService: firestoreService,
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final ConnectionRequestModel request;
  final FirestoreService firestoreService;

  const _RequestCard({
    required this.request,
    required this.firestoreService,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isActing = false;
  bool _isDone = false;
  bool _isAccepted = false;

  String get _initial {
    final name = widget.request.senderName;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isAccepted
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : AppTheme.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isAccepted ? Icons.check_circle_rounded : Icons.cancel_outlined,
              color: _isAccepted ? AppTheme.successColor : AppTheme.darkSubtext,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _isAccepted
                  ? 'Connected with ${widget.request.senderName}!'
                  : 'Request from ${widget.request.senderName} declined.',
              style: TextStyle(
                color: _isAccepted ? AppTheme.successColor : AppTheme.darkSubtext,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'wants to connect with you',
                        style: TextStyle(
                          color: AppTheme.darkSubtext,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(widget.request.createdAt),
                        style: const TextStyle(
                          color: AppTheme.darkSubtext,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pending badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppTheme.darkBorder, height: 1),
            const SizedBox(height: 12),

            // Actions
            if (_isActing)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Accept',
                      icon: Icons.check_rounded,
                      color: AppTheme.successColor,
                      filled: true,
                      onTap: _accept,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      color: AppTheme.errorColor,
                      filled: false,
                      onTap: _decline,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => _isActing = true);
    try {
      await widget.firestoreService.acceptConnectionRequest(widget.request);
      if (mounted) {
        setState(() {
          _isActing = false;
          _isDone = true;
          _isAccepted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connected with ${widget.request.senderName}! 🎉'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _isActing = true);
    try {
      await widget.firestoreService.rejectConnectionRequest(widget.request.id);
      if (mounted) {
        setState(() {
          _isActing = false;
          _isDone = true;
          _isAccepted = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isActing = false);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 64,
            color: AppTheme.darkSubtext.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pending requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're all caught up!",
            style: TextStyle(color: AppTheme.darkSubtext, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.darkSubtext),
          SizedBox(height: 12),
          Text(
            'Unable to load requests.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
