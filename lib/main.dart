import 'package:flutter/material.dart';
import 'package:LaaLingo/screens/RLSW/writing.dart';
import 'package:lottie/lottie.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:after_layout/after_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_page.dart';
import 'Splash/inital.dart';
import 'supabase_config.dart';

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
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightScheme =
            lightDynamic ?? ThemeData.light(useMaterial3: true).colorScheme;
        final darkScheme =
            darkDynamic ?? ThemeData.dark(useMaterial3: true).colorScheme;
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
          home: Splash(
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

class SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (context) => LoginPage(
                dync: widget.dync,
              )));
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (context) => InitPage(
                dync: widget.dync,
              )));
    }
  }

  @override
  void afterFirstLayout(BuildContext context) => checkFirstSeen();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: widget.dync.tertiaryContainer,
      body: new Center(child: new Text("🐼 🐼 🐼")),
    );
  }
}
