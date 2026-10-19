// lib/screens/profile/settings_screen.dart
//
// Settings screen for dark mode toggle, app info, and logout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 24),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of NeighbourHub?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        // Sign out from Firebase Auth
        await context.read<AuthService>().signOut();
        // Navigate directly to login screen — clear entire stack
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF13111C),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF13111C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),



          // ── About ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ABOUT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF1E1B2E),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  title: const Text('About NeighbourHub', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'NeighbourHub',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.house, color: Colors.white),
                      ),
                      children: const [
                        Text('Your neighbourhood, connected.'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFF2D2A45)),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
                  title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1B2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        title: const Text('Contact Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Email: srimadhu6521@gmail.com', style: TextStyle(color: Color(0xFF94A3B8))),
                            SizedBox(height: 8),
                            Text('Contact: 9823456734', style: TextStyle(color: Color(0xFF94A3B8))),
                            SizedBox(height: 8),
                            Text('Role: Community Administrator', style: TextStyle(color: Color(0xFF94A3B8))),
                            SizedBox(height: 8),
                            Text('Support: Available for community-related issues and assistance.', style: TextStyle(color: Color(0xFF94A3B8))),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor.withValues(alpha: 0.15),
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
