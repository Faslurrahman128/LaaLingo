import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'language_select_page.dart';
import 'settings_page.dart';

import 'RLSW/Listening.dart';
import 'RLSW/Reading.dart';
import 'RLSW/Speaking.dart';
import 'RLSW/writing.dart';
import '../leaderboard/leaderboard.dart';
import '../chatroom/chat_users_page.dart';
import '../translator/translator_ui.dart';

class LearningDashboardPage extends StatefulWidget {
  final ColorScheme dync;

  const LearningDashboardPage({required this.dync, super.key});

  @override
  State<LearningDashboardPage> createState() => _LearningDashboardPageState();
}

class _LearningDashboardPageState extends State<LearningDashboardPage> {
  int _tabIndex = 0;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = Supabase.instance.client.auth.currentUser;
    final metaName = user?.userMetadata?['name'];
    if (metaName is String && metaName.trim().isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _displayName = metaName.trim();
      });
      return;
    }

    final email = user?.email;
    if (email == null || email.isEmpty) return;

    try {
      final row = await Supabase.instance.client
          .from('user')
          .select('name')
          .eq('email', email)
          .maybeSingle();
      final name = row?['name'];
      final resolved = (name is String && name.trim().isNotEmpty)
          ? name.trim()
          : email;

      if (!mounted) return;
      setState(() {
        _displayName = resolved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = email;
      });
    }
  }

  void _resetToHome() {
    if (!mounted) return;
    setState(() {
      _tabIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dync = widget.dync;

    return Scaffold(
      backgroundColor: dync.primary,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard'),
            if (_displayName.trim().isNotEmpty)
              Text(
                'Hi, ${_displayName.trim()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change language',
            icon: const Icon(Icons.language),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LanguageSelectPage(dync: dync),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: dync.inversePrimary,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: GNav(
          selectedIndex: _tabIndex,
          duration: const Duration(milliseconds: 350),
          tabBorderRadius: 20,
          tabMargin: const EdgeInsets.all(3),
          color: dync.primary,
          tabBackgroundColor: dync.primary,
          activeColor: Colors.white,
          backgroundColor: dync.inversePrimary,
          tabs: const [
            GButton(icon: Icons.home, text: 'Home'),
            GButton(icon: Icons.translate, text: 'Translate'),
            GButton(icon: Icons.leaderboard, text: 'Leaderboard'),
            GButton(icon: Icons.settings, text: 'Settings'),
            GButton(icon: Icons.chat_bubble, text: 'Chat'),
          ],
          onTabChange: (value) {
            setState(() {
              _tabIndex = value;
            });

            if (value == 0) {
              return;
            }
            if (value == 1) {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TranslatorScreen(dync: dync)))
                  .then((_) => _resetToHome());
              return;
            }
            if (value == 2) {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: dync.primary,
                        appBar: AppBar(
                          backgroundColor: dync.primary,
                          foregroundColor: Colors.white,
                          title: const Text('Leaderboard'),
                        ),
                        body: SafeArea(
                          child: leaderboard(dync: dync),
                        ),
                      ),
                    ),
                  )
                  .then((_) => _resetToHome());
              return;
            }
            if (value == 3) {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SettingsPage(dync: dync)))
                  .then((_) => _resetToHome());
              return;
            }
            if (value == 4) {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ChatUsersPage(dync: dync)))
                  .then((_) => _resetToHome());
              return;
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            _Tile(
              label: 'Reading',
              assetPath: 'assets/reading.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => Reading(dync: dync)),
                );
              },
            ),
            _Tile(
              label: 'Listening',
              assetPath: 'assets/lis.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => listening(dync: dync)),
                );
              },
            ),
            _Tile(
              label: 'Speaking',
              assetPath: 'assets/speaking.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => Speaking(dync: dync)),
                );
              },
            ),
            _Tile(
              label: 'Writing',
              assetPath: 'assets/writing.png',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => Writing(dync: dync)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  const _Tile({required this.label, required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Flexible capsule height: scales with tile height but stays within sensible bounds.
            final capsuleHeight =
                (constraints.maxHeight * 0.26).clamp(70.0, 110.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Icon area (top)
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  bottom: capsuleHeight + 18,
                  child: Center(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // Black rounded capsule (bottom) - flexible height
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    height: capsuleHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(100),
                        topRight: Radius.circular(100),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
