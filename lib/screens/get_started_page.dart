import 'package:flutter/material.dart';
import 'login_page.dart';

class GetStartedPage extends StatelessWidget {
  final ColorScheme dync;
  const GetStartedPage({required this.dync, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dync.primary,
              dync.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: dync.onPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Image.asset(
                    'assets/AppIcon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Welcome to LaaLingo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dync.onPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Speak confidently, write clearly, and learn every day with guided language practice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dync.onPrimary.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: dync.onPrimary,
                      foregroundColor: dync.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginPage(dync: dync),
                        ),
                      );
                    },
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
