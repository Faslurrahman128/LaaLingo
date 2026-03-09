import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chartui.dart';

class ChatUsersPage extends StatelessWidget {
  final ColorScheme dync;

  const ChatUsersPage({required this.dync, super.key});

  @override
  Widget build(BuildContext context) {
    final meEmail = Supabase.instance.client.auth.currentUser?.email?.toLowerCase();

    return Scaffold(
      backgroundColor: dync.primary,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: Colors.white,
        title: const Text('Chat'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('user')
              .stream(primaryKey: ['email'])
              .order('leader_board', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Text('Loading ..', style: TextStyle(color: Colors.white)),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: Text('No users', style: TextStyle(color: Colors.white)),
              );
            }

            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            if (rows.isEmpty) {
              return const Center(
                child: Text('No users', style: TextStyle(color: Colors.white)),
              );
            }

            return ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final email = (row['email'] ?? '').toString();
                final name = (row['name'] ?? email).toString();
                final avatarUrl = row['avtar_url']?.toString();

                final isMe = meEmail != null && email.toLowerCase() == meEmail;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: dync.primaryContainer,
                    foregroundColor: dync.onPrimaryContainer,
                    backgroundImage: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    isMe ? '$name (You)' : name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  ),
                  trailing: isMe
                      ? null
                      : const Icon(Icons.chevron_right, color: Colors.white),
                  onTap: isMe
                      ? null
                      : () {
                          // Keep receiver id consistent with the existing leaderboard chat behavior.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => chatUI(
                                reciver: name.toLowerCase(),
                                reciver_name: name,
                                dync: dync,
                              ),
                            ),
                          );
                        },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
