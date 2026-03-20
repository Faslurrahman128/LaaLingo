import 'package:flutter/material.dart';
import 'package:LaaLingo/progress_brain.dart/progress.dart';
import 'package:lottie/lottie.dart';
import 'package:LaaLingo/screens/language_select_page.dart';
import 'package:LaaLingo/supabase_langs.dart';
import 'package:LaaLingo/screens/learning_dashboard_page.dart';
import 'package:LaaLingo/learning/learning.dart';
import 'package:LaaLingo/ResourcePage/resourcedownloading.dart';



class ResourceDownloading extends StatefulWidget {
  final String userEmail;
  late ColorScheme dync;
  ResourceDownloading({required this.userEmail, required this.dync});

  @override
  State<ResourceDownloading> createState() => _ResourceDownloadingState();
}

class _ResourceDownloadingState extends State<ResourceDownloading> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prog = progress();
      prog.userEmail = widget.userEmail;
      await prog.get_supabase_progress();
    } catch (_) {
      // Ignore: allow app to continue even if progress cannot load yet.
    }

    // If user still has no language selected, go to language selection.
    try {
      final userRow = progress().box.get('Lang');
      if (userRow is Map) {
        final slot1 = getLangSlot(userRow, 1);
        final selected = slot1?['Selected_lang'];
        final hasLangSelected = selected is List && selected.length >= 2;
        if (!hasLangSelected) {
          if (!mounted) return;
          // Clear history so back doesn't land on Login.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LanguageSelectPage(dync: widget.dync),
            ),
            (route) => false,
          );
          return;
        }
      }
    } catch (_) {
      // Ignore and continue to leaderboard.
    }

    // Ensure required seed data and correct-language translations are available in Hive.
    try {
      final box = progress().box;

      final userRow = box.get('Lang');
      final rawCurrent = box.get('current_lang');
      final currentLang = (rawCurrent is num)
          ? rawCurrent.toInt()
          : int.tryParse(rawCurrent?.toString() ?? '') ?? 1;
      final slot = getLangSlot(userRow, currentLang);
      final selected = slot?['Selected_lang'];
      final selectedCode = (selected is List && selected.length >= 2)
          ? selected[1].toString()
          : null;

      final hasSeedReading = box.get('Data_downloaded') is Map;
      final hasSeedSpeaking = box.get('SPEAKING') is Map;
      final translatedCode = box.get('translated_lang_code')?.toString();

      final needsSeed = !hasSeedReading || !hasSeedSpeaking;
      final needsTranslate =
          selectedCode != null && (translatedCode == null || translatedCode != selectedCode);

      if (needsSeed || needsTranslate) {
        final brain = ResourceBrain();
        brain.userEmail = widget.userEmail;
        if (currentLang == 1) {
          await brain.initaldownloadlang();
        } else {
          await brain.additionalangdownloadlang(currentLang);
        }
      }
    } catch (_) {
      // Ignore and continue; learning pages may prompt the user later.
    }

    if (!mounted) return;
    // Make the dashboard the root so back can't navigate to Login.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LearningDashboardPage(dync: widget.dync),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: widget.dync.primary,
      body: new Center(
          child: new LottieBuilder.asset("assets/animation_llgwflgi.json")),
    );
  }
}

