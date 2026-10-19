// lib/screens/neighbours/neighbour_profile_screen.dart
//
// Premium neighbour profile bottom-sheet/screen.
// Shows full profile info + live connection action depending on relationship.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user_model.dart';
import '../../models/connection_request_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class NeighbourProfileScreen extends StatefulWidget {
  final UserModel neighbour;
  final String connectionStatus; // none | sent | pending | connected
  final ConnectionRequestModel? pendingRequest;
  final UserModel? currentUser;
  final FirestoreService? firestoreService;

  const NeighbourProfileScreen({
    super.key,
    required this.neighbour,
    this.connectionStatus = 'none',
    this.pendingRequest,
    this.currentUser,
    this.firestoreService,
  });

  @override
  State<NeighbourProfileScreen> createState() => _NeighbourProfileScreenState();
}

class _NeighbourProfileScreenState extends State<NeighbourProfileScreen> {
  bool _isActing = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.connectionStatus;
  }

  String get _initials {
    final parts = widget.neighbour.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return widget.neighbour.name.isNotEmpty ? widget.neighbour.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.neighbour;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.darkBg,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1600), Color(0xFF0D0D0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: n.photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  n.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildInitial(),
                                ),
                              )
                            : _buildInitial(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        n.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (n.apartment.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home_outlined,
                                size: 13, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              n.apartment,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection action
                  _buildConnectionAction(context),
                  const SizedBox(height: 24),

                  // Info cards
                  _SectionHeader(label: 'DETAILS'),
                  const SizedBox(height: 10),

                  if (n.neighbourhood.isNotEmpty)
                    _InfoTile(
                      icon: Icons.location_city_outlined,
                      label: 'Community',
                      value: n.neighbourhood,
                    ),
                  if (n.apartment.isNotEmpty)
                    _InfoTile(
                      icon: Icons.home_outlined,
                      label: 'Apartment',
                      value: n.apartment,
                    ),
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: 'Joined ${timeago.format(n.createdAt)}',
                  ),

                  // Bio
                  if (n.bio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(label: 'ABOUT'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Text(
                        n.bio,
                        style: const TextStyle(
                          color: AppTheme.darkSubtext,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: AppTheme.infoColor, size: 16),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Contact details are private and never shared to protect your neighbour\'s privacy.',
                            style: TextStyle(
                              color: AppTheme.infoColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildConnectionAction(BuildContext context) {
    if (widget.firestoreService == null || widget.currentUser == null) {
      return const SizedBox.shrink();
    }

    if (_isActing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
        ),
      );
    }

    switch (_status) {
      case 'connected':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 18),
              SizedBox(width: 8),
              Text(
                '✓ Connected',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      case 'sent':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, color: AppTheme.darkSubtext, size: 18),
              SizedBox(width: 8),
              Text(
                'Request Sent',
                style: TextStyle(
                  color: AppTheme.darkSubtext,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _ProfileActionBtn(
                label: 'Accept Request',
                icon: Icons.check_rounded,
                color: AppTheme.successColor,
                onTap: () async {
                  if (widget.pendingRequest == null) return;
                  setState(() => _isActing = true);
                  await widget.firestoreService!.acceptConnectionRequest(widget.pendingRequest!);
                  if (mounted) {
                    setState(() { _status = 'connected'; _isActing = false; });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Connected with ${widget.neighbour.name}! 🎉'),
                      backgroundColor: AppTheme.successColor,
                    ));
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileActionBtn(
                label: 'Decline',
                icon: Icons.close_rounded,
                color: AppTheme.errorColor,
                outlined: true,
                onTap: () async {
                  if (widget.pendingRequest == null) return;
                  setState(() => _isActing = true);
                  await widget.firestoreService!.rejectConnectionRequest(widget.pendingRequest!.id);
                  if (mounted) {
                    setState(() { _status = 'none'; _isActing = false; });
                  }
                },
              ),
            ),
          ],
        );
      default:
        return _ProfileActionBtn(
          label: '+ Connect',
          icon: Icons.person_add_outlined,
          color: AppTheme.primaryColor,
          onTap: () async {
            setState(() => _isActing = true);
            await widget.firestoreService!.sendConnectionRequest(
              widget.currentUser!,
              widget.neighbour,
            );
            if (mounted) {
              setState(() { _status = 'sent'; _isActing = false; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Request sent to ${widget.neighbour.name} 📨'),
                backgroundColor: AppTheme.darkCard,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        );
    }
  }
}

class _ProfileActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ProfileActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: outlined ? 0.6 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: AppTheme.darkSubtext,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.darkSubtext,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
