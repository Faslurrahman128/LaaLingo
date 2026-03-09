import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:LaaLingo/supabase_langs.dart';

class progress {
  final client = Supabase.instance.client;
  String? userEmail;
  var box = Hive.box("LocalDB");

  int _sumProgressList(dynamic maybeList) {
    if (maybeList is! List) return 0;
    var sum = 0;
    for (final v in maybeList) {
      if (v is num) {
        sum += v.toInt();
      } else {
        sum += int.tryParse(v.toString()) ?? 0;
      }
    }
    return sum;
  }

  int _computeTotalProgress(Map<String, dynamic> langs) {
    var total = 0;
    for (final entry in langs.entries) {
      final slotData = entry.value;
      if (slotData is Map) {
        total += _sumProgressList(slotData['Progress']);
      }
    }
    return total;
  }

  List<int> progress_get() {
    final lastProg = box.get("Progress");
    if (lastProg is List) {
      try {
        return List<int>.from(lastProg.map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 0));
      } catch (_) {
        // fall through to defaults
      }
    }

    final defaults = <int>[0, 0, 0, 0];
    box.put("Progress", defaults);
    return List<int>.from(defaults);
  }

  Future<void> progress_update(pos) async {
    final lastProg = progress_get();
    final lastProgMutable = List<int>.from(lastProg);

    final idx = (pos is num) ? pos.toInt() : int.tryParse(pos.toString()) ?? 0;
    if (idx >= 0 && idx < lastProgMutable.length) {
      lastProgMutable[idx] = lastProgMutable[idx] + 1;
    }

    box.put("Progress", lastProgMutable);
    await update_supabase();
  }

  Future<void> update_supabase() async {
    final email = userEmail ?? client.auth.currentUser?.email;
    if (email == null || email.isEmpty) return;
    final last_prog = progress_get();

    final userRow = box.get('Lang');
    if (userRow is! Map) return;

    final currentLang = box.get('current_lang');
    final slot = (currentLang is num)
        ? currentLang.toInt()
        : int.tryParse(currentLang?.toString() ?? '') ?? 1;

    final slotData = getLangSlot(userRow, slot);
    if (slotData == null) return;
    final selectedLang = slotData['Selected_lang'];
    if (selectedLang == null) return;

    final currentLangs = extractLangs(userRow);
    final updatedLangs = upsertLangSlot(
      currentLangs: currentLangs,
      slot: slot,
      slotData: {
        ...slotData,
        'Selected_lang': selectedLang,
        'Progress': List<int>.from(last_prog),
      },
    );

    // Compute a consistent “stage/level” score based on completed progress.
    // We rank users by this total in the leaderboard.
    final totalProgress = _computeTotalProgress(updatedLangs);

    Future<void> doUpdate() => client.from('user').update({
          'langs': updatedLangs,
          'leader_board': totalProgress,
        }).eq('email', email);

    try {
      await doUpdate();

      // Keep local cache in sync so future updates don't get stuck.
      final nextUserRow = Map<String, dynamic>.from(userRow);
      nextUserRow['langs'] = updatedLangs;
      nextUserRow['leader_board'] = totalProgress;
      box.put('Lang', nextUserRow);
    } on PostgrestException catch (e) {
      final code = (e.code ?? '').toString();
      final message = (e.message).toString().toLowerCase();
      final isSchemaCache = code == 'PGRST204' || message.contains('schema cache');
      if (isSchemaCache) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await doUpdate();

          final nextUserRow = Map<String, dynamic>.from(userRow);
          nextUserRow['langs'] = updatedLangs;
          nextUserRow['leader_board'] = totalProgress;
          box.put('Lang', nextUserRow);
        } catch (_) {
          // Keep local progress; schema cache will refresh soon.
        }
      }
    }
  }

  Future<void> get_supabase_progress() async {
    final email = userEmail ?? client.auth.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final userRes = await client
        .from('user')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (userRes == null) {
      // User profile row not created yet.
      // Keep local defaults so the app can continue running.
      box.put("Lang", <String, dynamic>{'email': email});
      progress_get();
      return;
    }

    box.put("Lang", userRes);
    box.put('count_lang', deriveCountLang(userRes));
    final currentLang = box.get("current_lang")?.toString();
    if (currentLang == null || currentLang.isEmpty) {
      progress_get();
      return;
    }

    final slot = int.tryParse(currentLang) ?? 1;
    final langData = getLangSlot(userRes, slot);
    if (langData != null && langData['Progress'] is List) {
      box.put('Progress', List<int>.from((langData['Progress'] as List).map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 0)));
    } else {
      progress_get();
    }
  }
}
