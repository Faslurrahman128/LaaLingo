import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:LaaLingo/ResourcePage/Resource.dart';
import 'package:LaaLingo/supabase_langs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ResourcePage/resourcedownloading.dart';

class LanguageSelectPage extends StatefulWidget {
  final ColorScheme dync;
  const LanguageSelectPage({required this.dync, super.key});

  @override
  State<LanguageSelectPage> createState() => _LanguageSelectPageState();
}

class _LanguageSelectPageState extends State<LanguageSelectPage> {
  final List<List<dynamic>> _langAvail = [
    ["English", "en", "US"],
    ["German", "de", "DE"],
    ["Japanese", "ja", "JP"],
    ["Russian", "ru", "RU"],
    ["Korean", "ko", "KR"],
    ["French", "fr", "PM"],
    ["Malayalam", "ml", "IN"],
    ["Tamil", "ta", "IN"],
    ["Hindi", "hi", "IN"],
    ["Kannada", "kn", "IN"],
    ["Sinhala", "si", "LK"],
  ];

  int _selected = 0;
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _hydrateCurrentSelection();
  }

  void _hydrateCurrentSelection() {
    try {
      final box = Hive.box('LocalDB');
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

      if (selectedCode == null || selectedCode.isEmpty) return;

      final idx = _langAvail.indexWhere(
        (e) => e.length >= 2 && e[1].toString() == selectedCode,
      );
      if (idx < 0) return;

      _selected = idx;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_scrollController.hasClients) return;

        // ListTile is typically ~72px tall; use an approximate jump.
        final target = (idx * 72.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
        setState(() {});
      });
    } catch (_) {
      // Ignore: page still works with default selection.
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _flagFor(List<dynamic> lang) {
    final code = (lang.length >= 3 ? lang[2] : null)?.toString().trim();
    if (code == null || code.isEmpty) {
      return const Icon(Icons.flag_outlined);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SvgPicture.asset(
        'assets/flag/$code.svg',
        width: 28,
        height: 20,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const SizedBox(
          width: 28,
          height: 20,
          child: Center(child: Icon(Icons.flag_outlined, size: 16)),
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _confirmAndContinue() async {
    if (_isProcessing) return;

    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _message('No logged in user found. Please log in again.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          color: Colors.black.withOpacity(0.2),
          child: const Center(
            child: SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        );
      },
    );

    try {
      final resourcebrain = ResourceBrain();
      await resourcebrain.addUserdetails(_langAvail[_selected], email);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResourceDownloading(
            userEmail: email,
            dync: widget.dync,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _message(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dync = widget.dync;
    return Scaffold(
      backgroundColor: dync.onPrimaryContainer,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: Colors.white,
        title: const Text('Select Language'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Choose your first learning language:',
              style: TextStyle(
                color: dync.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _langAvail.length,
              itemBuilder: (context, index) {
                final lang = _langAvail[index];
                final isSelected = index == _selected;
                return ListTile(
                  leading: _flagFor(lang),
                  title: Text(lang[0].toString()),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: widget.dync.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selected = index;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: dync.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isProcessing ? null : _confirmAndContinue,
                child:
                    Text(_isProcessing ? 'Please wait...' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
