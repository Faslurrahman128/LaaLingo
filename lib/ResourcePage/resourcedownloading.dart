import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart';
import 'package:LaaLingo/supabase_langs.dart';

class ResourceBrain {
  var box = Hive.box("LocalDB");
  final client = Supabase.instance.client;
  GoogleTranslator translator = GoogleTranslator();
  String? userEmail;

  late List<dynamic> Question;

  Future<void> initaldownloadlang() async {
    final email = userEmail ?? client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('No authenticated user email found');
    }
    userEmail = email;
    box.put("current_lang", 1);

    // Prefer cached user/lang data when available (avoids RLS/select issues).
    Map<dynamic, dynamic>? userRes;
    final cached = box.get('Lang');
    if (cached is Map && (cached['email']?.toString() ?? '').toLowerCase() == email.toLowerCase()) {
      userRes = cached;
    }

    userRes ??= await client
        .from('user')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (userRes == null) {
      throw Exception(
        'User profile row not found (0 rows). Please select a language first, or ensure your Supabase RLS policies allow selecting your own row in table `user`.',
      );
    }

    await box.put("Lang", userRes);
    await box.put("count_lang", deriveCountLang(userRes));
    print(box.get("count_lang"));

    final slot = getLangSlot(userRes, 1);
    final lang = slot?['Selected_lang'];
    if (lang is! List || lang.length < 2) {
      throw Exception('No language selected yet. Please select a language first.');
    }
    // Track which language code the cached translated content corresponds to.
    // This allows us to refresh translations when the user switches language.
    box.put('translated_lang_code', lang[1].toString());
    box.put('translated_lang_slot', 1);

    // Fetch English_Data from Supabase
    final dataRes = await client
        .from('DataBase')
        .select()
        .eq('name', 'English_Data')
        .maybeSingle();
    if (dataRes == null) {
      throw Exception(
        'Could not load seed row from Supabase table `DataBase` (0 rows): name = English_Data.\n'
        'Either the row is missing OR RLS/policies are blocking SELECT.\n\n'
        'Fix: ensure the row exists, and if RLS is enabled, add a SELECT policy for authenticated users.',
      );
    }
    box.put("Data_downloaded", dataRes['data']);
    print(dataRes['data']);
    final RawData = (dataRes['data'] as Map).cast<dynamic, dynamic>();
    for (final entry in RawData.entries) {
      final key = entry.key;
      Question = await translatefunction(RawData, key, translator, lang[1]);
      await box.put(key.toString(), Question);
    }

    // Fetch LISTENING from Supabase
    final listeningRes = await client
        .from('DataBase')
        .select()
        .eq('name', 'LISTENING')
        .maybeSingle();
    if (listeningRes == null) {
      throw Exception(
        'Could not load seed row from Supabase table `DataBase` (0 rows): name = LISTENING.\n'
        'Either the row is missing OR RLS/policies are blocking SELECT.\n\n'
        'Fix: ensure the row exists, and if RLS is enabled, add a SELECT policy for authenticated users.',
      );
    }
    box.put('SPEAKING', listeningRes['data']);
    print(listeningRes['data']);
    final SpeakingRawData = (listeningRes['data'] as Map).cast<dynamic, dynamic>();
    for (final entry in SpeakingRawData.entries) {
      final key = entry.key;
      Question = await translatefunction(SpeakingRawData, key, translator, lang[1]);
      await box.put(key.toString(), Question);
    }
  }

  Future<void> additionalangdownloadlang(int n) async {
    final email = userEmail ?? client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('No authenticated user email found');
    }
    userEmail = email;

    Map<dynamic, dynamic>? userRes;
    final cached = box.get('Lang');
    if (cached is Map && (cached['email']?.toString() ?? '').toLowerCase() == email.toLowerCase()) {
      userRes = cached;
    }
    userRes ??= await client
        .from('user')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (userRes == null) {
      throw Exception(
        'User profile row not found (0 rows). Please ensure your Supabase RLS policies allow selecting your own row in table `user`.',
      );
    }

    box.put("Lang", userRes);
    box.put("count_lang", deriveCountLang(userRes));

    final dataRes = await client
        .from('DataBase')
        .select()
        .eq('name', 'English_Data')
        .maybeSingle();
    if (dataRes == null) {
      throw Exception(
        'Could not load seed row from Supabase table `DataBase` (0 rows): name = English_Data.\n'
        'Either the row is missing OR RLS/policies are blocking SELECT.\n\n'
        'Fix: ensure the row exists, and if RLS is enabled, add a SELECT policy for authenticated users.',
      );
    }
    box.put("Data_downloaded", dataRes['data']);

    final listeningRes = await client
        .from('DataBase')
        .select()
        .eq('name', 'LISTENING')
        .maybeSingle();
    if (listeningRes == null) {
      throw Exception(
        'Could not load seed row from Supabase table `DataBase` (0 rows): name = LISTENING.\n'
        'Either the row is missing OR RLS/policies are blocking SELECT.\n\n'
        'Fix: ensure the row exists, and if RLS is enabled, add a SELECT policy for authenticated users.',
      );
    }
    box.put('SPEAKING', listeningRes['data']);

    final slot = getLangSlot(userRes, n);
    final lang = slot?['Selected_lang'];
    if (lang is! List || lang.length < 2) {
      throw Exception('No language selected for slot $n');
    }
    box.put("current_lang", n);

    // Track which language code the cached translated content corresponds to.
    box.put('translated_lang_code', lang[1].toString());
    box.put('translated_lang_slot', n);

    final RawData = (box.get("Data_downloaded") as Map).cast<dynamic, dynamic>();
    for (final entry in RawData.entries) {
      final key = entry.key;
      Question = await translatefunction(RawData, key, translator, lang[1]);
      await box.put(key.toString(), Question);
    }

    final SpeakingRawData = (box.get("SPEAKING") as Map).cast<dynamic, dynamic>();
    for (final entry in SpeakingRawData.entries) {
      final key = entry.key;
      Question = await translatefunction(SpeakingRawData, key, translator, lang[1]);
      await box.put(key.toString(), Question);
    }
  }

  Future addUserdetails(List selectedlang, String email) async {
    final existing = await client
        .from('user')
        .select()
        .eq('email', email)
        .maybeSingle();

    final currentLangs = extractLangs(existing);
    final updatedLangs = upsertLangSlot(
      currentLangs: currentLangs,
      slot: 1,
      slotData: {
        'Selected_lang': selectedlang,
        'Progress': [0, 0, 0, 0],
        'name': email,
      },
    );

    Future<void> doUpsert() => client.from('user').upsert({
          'email': email,
          'langs': updatedLangs,
          'count_lang': 1,
          'leader_board': 0,
        }, onConflict: 'email');

    try {
      await doUpsert();
    } on PostgrestException catch (e) {
      if (_isLangsSchemaCacheError(e)) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await doUpsert();
        } on PostgrestException catch (e2) {
          throw Exception(_langsSchemaHelpMessage(e2));
        }
      } else {
        throw Exception(_langsSchemaHelpMessage(e));
      }
    }

    // Cache the selected language locally so we can proceed even if `select` is blocked by RLS.
    final localRow = <String, dynamic>{
      'email': email,
      'langs': updatedLangs,
      'count_lang': 1,
      'leader_board': 0,
    };
    box.put('Lang', localRow);
    box.put('count_lang', 1);
    box.put("current_lang", 1);

    // Force next bootstrap to refresh translated learning content.
    // (Otherwise existing cached translations remain in the previous language.)
    box.delete('translated_lang_code');
    box.delete('translated_lang_slot');
  }

  Future appendlang(List selectedlang, String email, String name) async {
    final existing = await client
        .from('user')
        .select()
        .eq('email', email)
        .maybeSingle();

    final currentCount = deriveCountLang(existing);
    final nextSlot = currentCount + 1;
    box.put('count_lang', nextSlot);

    final currentLangs = extractLangs(existing);
    final updatedLangs = upsertLangSlot(
      currentLangs: currentLangs,
      slot: nextSlot,
      slotData: {
        'Selected_lang': selectedlang,
        'Progress': [0, 0, 0, 0],
        'name': name,
      },
    );

    Future<void> doUpdate() => client.from('user').update({
          'langs': updatedLangs,
          'count_lang': nextSlot,
        }).eq('email', email);

    try {
      await doUpdate();
    } on PostgrestException catch (e) {
      if (_isLangsSchemaCacheError(e)) {
        await Future.delayed(const Duration(seconds: 2));
        try {
          await doUpdate();
        } on PostgrestException catch (e2) {
          throw Exception(_langsSchemaHelpMessage(e2));
        }
      } else {
        throw Exception(_langsSchemaHelpMessage(e));
      }
    }

    // Cache updated langs locally; don't require a follow-up `select` (can be blocked by RLS).
    final localRow = <String, dynamic>{
      'email': email,
      'langs': updatedLangs,
      'count_lang': nextSlot,
    };
    box.put('Lang', localRow);
    box.put("current_lang", box.get("count_lang"));
    additionalangdownloadlang(box.get("current_lang"));
  }

  Future<List> translatefunction(RawData, key, translator, tolang) async {
    List TempQuestion = RawData[key];
    for (int i = 0; i < TempQuestion.length; i++) {
      await translator
          .translate(TempQuestion[i], to: tolang.toString())
          .then((value) {
        TempQuestion[i] = value.text;
      });
    }
    return TempQuestion;
  }

  bool _isLangsSchemaCacheError(PostgrestException e) {
    final code = (e.code ?? '').toString();
    final message = (e.message).toString().toLowerCase();
    return code == 'PGRST204' ||
        message.contains('schema cache') ||
        message.contains("could not find the 'langs' column") ||
        message.contains('could not find the "langs" column');
  }

  String _langsSchemaHelpMessage(PostgrestException e) {
    return 'Database schema is missing required column `langs` (jsonb) on table `user`, '
        'or PostgREST schema cache has not refreshed yet.\n\n'
        'If you already added the column, run this once in Supabase SQL Editor and wait ~30s:\n'
        "notify pgrst, 'reload schema';\n\n"
        'Original error: ${e.message}';
  }
}
