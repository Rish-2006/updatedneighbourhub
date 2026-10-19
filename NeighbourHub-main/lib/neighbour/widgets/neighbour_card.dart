// lib/widgets/neighbour_card.dart
//
// Card widget showing a neighbour's basic info in the Neighbours screen.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';

class NeighbourCard extends StatelessWidget {
  final UserModel neighbour;
  final VoidCallback? onViewProfile;
  final int index;
  final String? connectionStatus;
  final VoidCallback? onSendRequest;
  final VoidCallback? onAcceptRequest;
  final VoidCallback? onRejectRequest;

  const NeighbourCard({
    super.key,
    required this.neighbour,
    this.onViewProfile,
    this.index = 0,
    this.connectionStatus,
    this.onSendRequest,
    this.onAcceptRequest,
    this.onRejectRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewProfile,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                backgroundImage: neighbour.photoUrl.isNotEmpty
                    ? NetworkImage(neighbour.photoUrl)
                    : null,
                child: neighbour.photoUrl.isEmpty
                    ? Text(
                        neighbour.name.isNotEmpty
                            ? neighbour.name[0].toUpperCase()
                            : 'N',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Name and Bio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      neighbour.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (neighbour.bio.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        neighbour.bio,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (neighbour.apartment.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 13,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            neighbour.apartment,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              if (connectionStatus == null)
                TextButton(
                  onPressed: onViewProfile,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('View', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                )
              else if (connectionStatus == 'none')
                ElevatedButton(
                  onPressed: onSendRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  child: const Text('Send', style: TextStyle(fontSize: 12)),
                )
              else if (connectionStatus == 'sent')
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  child: const Text('Requested', style: TextStyle(fontSize: 12)),
                )
              else if (connectionStatus == 'connected')
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  ),
                  child: Text('Connected', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                )
              else if (connectionStatus == 'received')
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: onAcceptRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(60, 26),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: onRejectRequest,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: const Size(60, 26),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 300.ms)
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }
}
