// lib/screens/neighbours/my_neighbours_screen.dart
//
// Premium My Connections screen — shows all connected neighbours.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import 'neighbour_profile_screen.dart';

class MyNeighboursScreen extends StatelessWidget {
  const MyNeighboursScreen({super.key});

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
          'My Connections',
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
      body: StreamBuilder<List<String>>(
        stream: firestoreService.getConnectedUserIdsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load connections.',
                style: TextStyle(color: AppTheme.darkSubtext, fontSize: 16),
              ),
            );
          }

          final connectedIds = snapshot.data ?? [];

          if (connectedIds.isEmpty) {
            return _EmptyConnections();
          }

          return FutureBuilder<List<UserModel>>(
            future: _fetchUsers(firestoreService, connectedIds),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              final neighbours = userSnapshot.data ?? [];

              return Column(
                children: [
                  // Header summary
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.handshake_outlined,
                            color: AppTheme.successColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${neighbours.length} connection${neighbours.length != 1 ? 's' : ''} in your community',
                          style: const TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: neighbours.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final neighbour = neighbours[index];
                        return _ConnectedCard(
                          neighbour: neighbour,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NeighbourProfileScreen(
                                neighbour: neighbour,
                                connectionStatus: 'connected',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<UserModel>> _fetchUsers(FirestoreService fs, List<String> ids) async {
    final List<UserModel> users = [];
    for (final id in ids) {
      final user = await fs.getUser(id);
      if (user != null) users.add(user);
    }
    return users;
  }
}

class _ConnectedCard extends StatelessWidget {
  final UserModel neighbour;
  final VoidCallback onTap;

  const _ConnectedCard({required this.neighbour, required this.onTap});

  String get _initials {
    final parts = neighbour.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return neighbour.name.isNotEmpty ? neighbour.name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.35)),
              ),
              child: neighbour.photoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        neighbour.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildInitial(),
                      ),
                    )
                  : _buildInitial(),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neighbour.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (neighbour.apartment.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.home_outlined,
                            size: 12, color: AppTheme.darkSubtext),
                        const SizedBox(width: 4),
                        Text(
                          neighbour.apartment,
                          style: const TextStyle(
                            color: AppTheme.darkSubtext,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 12, color: AppTheme.successColor),
                      const SizedBox(width: 4),
                      Text(
                        'Connected ${timeago.format(neighbour.createdAt)}',
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.darkSubtext, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppTheme.successColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyConnections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 64,
            color: AppTheme.darkSubtext.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No connections yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with neighbours in your community.',
            style: TextStyle(color: AppTheme.darkSubtext, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.people_outline_rounded, color: AppTheme.primaryColor),
            label: const Text(
              'Browse Neighbours',
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
