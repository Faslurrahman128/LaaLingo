import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:LaaLingo/supabase_langs.dart';

final box = Hive.box("LocalDB");

class listening extends StatefulWidget {
  late ColorScheme dync;
  listening({required this.dync, super.key});

  @override
  State<listening> createState() => _listeningState();
}

class _listeningState extends State<listening> {
  List<dynamic> lang = const ['English', 'en', ''];
  Map<dynamic, dynamic> listeningRaw = <dynamic, dynamic>{};
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  String _ttsLocale = '';

  @override
  void initState() {
    super.initState();

    final userRow = box.get('Lang');
    final rawCurrent = box.get('current_lang');
    final currentLang = (rawCurrent is num)
        ? rawCurrent.toInt()
        : int.tryParse(rawCurrent?.toString() ?? '') ?? 1;
    final slot = getLangSlot(userRow, currentLang);
    final selected = slot?['Selected_lang'];
    if (selected is List && selected.isNotEmpty) {
      lang = selected.cast<dynamic>();
    }

    final raw = box.get('SPEAKING');
    if (raw is Map) {
      listeningRaw = raw.cast<dynamic, dynamic>();
    }

    // Configure TTS after first frame so we can show SnackBars.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureTtsForSelectedLanguage();
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _preferredTtsLocale(List<dynamic> selectedLang) {
    final code = (selectedLang.length >= 2)
        ? selectedLang[1].toString().trim().toLowerCase()
        : 'en';

    switch (code) {
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'ja':
        return 'ja-JP';
      case 'ru':
        return 'ru-RU';
      case 'ko':
        return 'ko-KR';
      case 'fr':
        return 'fr-FR';
      case 'ml':
        return 'ml-IN';
      case 'ta':
        return 'ta-IN';
      case 'hi':
        return 'hi-IN';
      case 'kn':
        return 'kn-IN';
      case 'si':
        return 'si-LK';
      default:
        return code;
    }
  }

  Future<bool> _trySetLanguage(String locale) async {
    try {
      final res = await _tts.setLanguage(locale);
      // Some platforms return a bool, some return a String.
      if (res is bool) return res;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _configureTtsForSelectedLanguage() async {
    if (lang.length < 2) return;

    final locale = _preferredTtsLocale(lang);
    final code = lang[1].toString();

    bool ok = await _trySetLanguage(locale);
    if (!ok && locale != code) {
      ok = await _trySetLanguage(code);
    }

    _ttsReady = ok;
    _ttsLocale = ok ? (locale) : '';

    if (!ok) {
      final langName = (lang.isNotEmpty ? lang[0].toString() : 'this language');
      _message('Voice not available for $langName on this device/browser.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = listeningRaw.keys
        .map((e) => e.toString())
        .toSet()
        .toList(growable: false);

    String titleFor(String key) {
      if (key == 'Quick_Listen_Practice') return 'Quick Listen Practice';
      if (key == 'Listening_Challenge') return 'Listening Challenge';
      return key.replaceAll('_', ' ');
    }

    return Material(
      child: Scaffold(
        backgroundColor: widget.dync.primary,
        appBar: AppBar(
          backgroundColor: widget.dync.primary,
          foregroundColor: widget.dync.onPrimary,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Listening",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 1.28,
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        'Listening data not found. Please download language data first.',
                        style: TextStyle(color: widget.dync.onPrimary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final translated = box.get(cat);
                        final rawItems = (translated is List)
                            ? translated
                            : (listeningRaw[cat] is List)
                                ? (listeningRaw[cat] as List)
                                : const <dynamic>[];

                        final seen = <String>{};
                        final items = <dynamic>[];
                        for (final item in rawItems) {
                          final key = item.toString().trim().toLowerCase();
                          if (key.isEmpty || seen.contains(key)) continue;
                          seen.add(key);
                          items.add(item);
                        }

                        return ExpansionTile(
                          title: Text(
                            titleFor(cat),
                            style: TextStyle(
                              color: widget.dync.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: [
                            for (final item in items)
                              ListTile(
                                title: Text(item.toString()),
                                trailing: const Icon(Icons.volume_up),
                                onTap: () async {
                                  try {
                                    if (!_ttsReady) {
                                      final langName = (lang.isNotEmpty
                                          ? lang[0].toString()
                                          : 'this language');
                                      _message(
                                          'TTS is not available for $langName here.');
                                      return;
                                    }
                                    await _tts.speak(item.toString());
                                  } catch (_) {
                                    _message('Could not play audio for this item.');
                                  }
                                },
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
