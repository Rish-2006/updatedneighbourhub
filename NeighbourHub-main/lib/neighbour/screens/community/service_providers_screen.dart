// lib/neighbour/screens/community/service_providers_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import 'service_provider_details_screen.dart';

class ServiceProvidersScreen extends StatelessWidget {
  final String category;

  const ServiceProvidersScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('$category Providers'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_providers')
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 12),
                  const Text('Unable to load service providers. Please try again.',
                      style: TextStyle(color: AppTheme.darkSubtext)),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading ${category.toLowerCase()}s...',
                      style: const TextStyle(color: AppTheme.darkSubtext)),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 64, color: AppTheme.darkSubtext.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No service providers are currently available.',
                    style: TextStyle(color: AppTheme.darkSubtext, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final name = data['name'] as String? ?? 'Unknown';
              final phone = data['phone'] as String? ?? '';
              final experience = data['experience'] as String? ?? '';
              final location = data['location'] as String? ?? '';
              final availability = data['availability'] as String? ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppTheme.darkCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.darkBorder),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceProviderDetailsScreen(
                          providerData: data,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    category,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(icon: Icons.phone_outlined, text: phone),
                        const SizedBox(height: 6),
                        _InfoRow(icon: Icons.location_on_outlined, text: location),
                        const SizedBox(height: 6),
                        _InfoRow(icon: Icons.star_border_outlined, text: experience),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('🟢', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              availability.isNotEmpty ? availability : 'Available',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: AppTheme.darkSubtext),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.darkSubtext),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.darkSubtext,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
