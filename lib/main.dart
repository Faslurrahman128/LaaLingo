import 'package:flutter/material.dart';
import 'package:LaaLingo/screens/RLSW/writing.dart';
import 'package:lottie/lottie.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import 'screens/login_page.dart';
import 'screens/get_started_page.dart';
import 'supabase_config.dart';
import 'screens/reset_password_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('LocalDB');
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Map<String, String> _parseFragmentParams(Uri uri) {
    if (uri.fragment.isEmpty) return const {};
    try {
      return Uri.splitQueryString(uri.fragment);
    } catch (_) {
      return const {};
    }
  }

  Map<String, dynamic> _extractRecovery(Uri uri) {
    final fragmentParams = _parseFragmentParams(uri);
    final accessToken =
        uri.queryParameters['access_token'] ?? fragmentParams['access_token'] ?? '';
    final refreshToken =
        uri.queryParameters['refresh_token'] ?? fragmentParams['refresh_token'] ?? '';
    final type = uri.queryParameters['type'] ?? fragmentParams['type'] ?? '';
    final isRecoveryRoute = uri.path == '/reset-password';
    final isRecoveryType = type.toLowerCase() == 'recovery';

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'isRecovery': (isRecoveryRoute || isRecoveryType) &&
          accessToken.isNotEmpty &&
          refreshToken.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme =
            lightDynamic ?? ThemeData.light(useMaterial3: true).colorScheme;
        final darkScheme =
            darkDynamic ?? ThemeData.dark(useMaterial3: true).colorScheme;
        final recovery = _extractRecovery(Uri.base);
        return MaterialApp(
          title: 'LaaLingo',
          theme: ThemeData(
            fontFamily: 'Ubuntu',
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: 'Ubuntu',
            colorScheme: darkScheme,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: (recovery['isRecovery'] as bool)
              ? ResetPasswordPage(
                  accessToken: recovery['accessToken'] as String,
                  refreshToken: recovery['refreshToken'] as String,
                )
              : Splash(
                  dync: lightScheme,
                ),
        );
      },
    );
  }
}

class Splash extends StatefulWidget {
  late ColorScheme dync;
  Splash({required this.dync});

  @override
  SplashState createState() => new SplashState();
}

class SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GetStartedPage(
            dync: widget.dync,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final iconSize = (shortestSide * 0.52).clamp(160.0, 420.0);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.dync.primary,
                  widget.dync.primaryContainer,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: iconSize,
                height: iconSize,
                padding: EdgeInsets.all(iconSize * 0.12),
                decoration: BoxDecoration(
                  color: widget.dync.onPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(iconSize * 0.24),
                  border: Border.all(
                    color: widget.dync.onPrimary.withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/AppIcon.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
