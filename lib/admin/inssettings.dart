import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_auth.dart';
import 'inslogin.dart';

class InsSettingsPage extends StatelessWidget {
  final ColorScheme dync;
  const InsSettingsPage({required this.dync, super.key});

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseAuth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Inslogin(dync: dync)),
      (_) => false,
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Instructor Panel'),
          content: const Text(
            'LaaLingo Instructor Panel\n\nUse this area to manage student requests and communications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: dync.primary,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: Colors.white,
        title: const Text('Instructor Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: dync.inversePrimary,
              leading: Icon(Icons.person, color: dync.primary),
              title: Text(
                'Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dync.primary,
                ),
              ),
              subtitle: email.isEmpty
                  ? null
                  : Text(
                      email,
                      style: TextStyle(color: dync.primary.withOpacity(0.8)),
                    ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: dync.inversePrimary,
              leading: Icon(Icons.info_outline, color: dync.primary),
              title: Text(
                'About',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dync.primary,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: dync.primary),
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: dync.inversePrimary,
              leading: Icon(Icons.logout, color: dync.error),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: dync.error,
                ),
              ),
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showMessage(context, 'Settings are ready.'),
              child: const Text('Status: Active'),
            )
          ],
        ),
      ),
    );
  }
}
