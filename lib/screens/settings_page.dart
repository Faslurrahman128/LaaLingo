import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'language_select_page.dart';
import 'login_page.dart';
import 'forgot_password_otp_page.dart';
import '../supabase_auth.dart';
import '../supabase_config.dart';

class SettingsPage extends StatelessWidget {
  final ColorScheme dync;

  const SettingsPage({required this.dync, super.key});

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final controller = TextEditingController();
    final currentName = Supabase.instance.client.auth.currentUser?.userMetadata?['name'];
    if (currentName is String && currentName.trim().isNotEmpty) {
      controller.text = currentName.trim();
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final newName = result?.trim() ?? '';
    if (newName.isEmpty) return;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'name': newName},
        ),
      );
    } catch (_) {
      _showMessage(context, 'Could not update name in auth profile.');
      return;
    }

    // Best-effort: keep your app DB row in sync (leaderboard uses `user.name`).
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('user')
            .update({'name': newName})
            .eq('email', email);
      } catch (_) {
        // Ignore (may be blocked by RLS). Auth metadata is still updated.
      }
    }

    _showMessage(context, 'Name updated.');
  }

  Future<void> _showAbout(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('About'),
          content: const Text(
            'LaaLingo\n\nA language learning app with reading, listening, speaking, and writing practice.',
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

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text(
            'This permanently deletes your account. You will NOT be able to log in again with this account.\n\n'
            'This requires the deployed Supabase Edge Function: delete-account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {
      // ignore
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      _showMessage(context, 'Your session has expired. Please log in again.');
      return;
    }

    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/delete-account');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${session.accessToken}',
              // Supabase gateway/web sometimes forwards JWT via this header.
              'x-supabase-authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode(const {}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        _showMessage(context, 'Delete failed (${res.statusCode}): ${res.body}');
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['ok'] == true) {
        // ok
      } else {
        _showMessage(context, 'Delete response: $decoded');
      }
    } catch (e) {
      _showMessage(context, 'Full deletion failed: ${e.toString()}');
      return;
    }

    await _signOut(context);
  }



  Future<void> _signOut(BuildContext context) async {
    final box = Hive.box('LocalDB');

    try {
      await SupabaseAuth.signOut();
    } catch (_) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }

    try {
      await box.clear();
    } catch (_) {}

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(dync: dync),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dync = this.dync;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: dync.primary,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
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
              leading: Icon(Icons.language, color: dync.primary),
              title: Text(
                'Change language',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dync.primary,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: dync.primary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LanguageSelectPage(dync: dync),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: dync.inversePrimary,
              leading: Icon(Icons.lock_reset, color: dync.primary),
              title: Text(
                'Reset password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dync.primary,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: dync.primary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ForgotPasswordOtpPage(dync: dync),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: dync.inversePrimary,
              leading: Icon(Icons.edit, color: dync.primary),
              title: Text(
                'Edit display name',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: dync.primary,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: dync.primary),
              onTap: () => _editDisplayName(context),
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
              leading: Icon(Icons.delete_forever, color: dync.error),
              title: Text(
                'Delete account',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: dync.error,
                ),
              ),
              subtitle: Text(
                'Permanently deletes your account.',
                style: TextStyle(color: dync.error.withOpacity(0.85)),
              ),
              onTap: () => _deleteAccount(context),
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
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
