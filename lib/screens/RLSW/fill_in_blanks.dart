import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FillInBlanksPage extends StatefulWidget {
  final ColorScheme dync;

  const FillInBlanksPage({required this.dync, super.key});

  @override
  State<FillInBlanksPage> createState() => _FillInBlanksPageState();
}

class _FillInBlanksPageState extends State<FillInBlanksPage> {
  final box = Hive.box('LocalDB');
  final Random _random = Random();

  final List<Map<String, dynamic>> _items = [];
  final List<int> _order = [];

  int _current = 0;
  int _score = 0;
  bool _finished = false;
  // Reference categories from Reading.dart
  final List<String> _categories = [
    "Basic_Words",
    "MCQ/Match Exercise",
    "Numbers",
    "Fill in the Blanks",
    "Colors_Data",
    "Puzzles Exercise",
    "Food_Data",
    "Animals_Data",
    "Vocabulary",
    "Everyday_Essentials",
    "Travel_Talk",
    "Grammar_and_Usage_Drill",
    "Phrases and Expressions",
    "Grammar",
    "Dialogues and Conversations",
    "Image Based Questions",
    "Cultural Insights",
  ];
  String? _selected;

  @override
  void initState() {
    super.initState();
    _prepareItems();
  }

  void _prepareItems() {
    final raw = box.get('Data_downloaded');
    final data = (raw is Map) ? raw.cast<dynamic, dynamic>() : <dynamic, dynamic>{};

    List<dynamic> listOf(String key) {
      final value = data[key];
      if (value is List) return value;
      return const <dynamic>[];
    }

    final candidates = <String>[];
    final sources = <dynamic>[
      ...listOf('Grammar'),
      ...listOf('Phrases and Expressions'),
      ...listOf('Dialogues and Conversations'),
      ...listOf('Cultural Insights'),
    ];

    for (final s in sources) {
      final text = s.toString().trim();
      if (text.split(RegExp(r'\s+')).length >= 3) {
        candidates.add(text);
      }
    }

    final shuffled = [...candidates]..shuffle(_random);
    final selectedSentences = shuffled.take(8).toList();

    final wordPool = <String>{};
    for (final sentence in selectedSentences) {
      for (final token in sentence.split(RegExp(r'\s+'))) {
        final clean = token.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
        if (clean.length > 2) {
          wordPool.add(clean);
        }
      }
    }

    for (final sentence in selectedSentences) {
      final words = sentence.split(RegExp(r'\s+'));
      final candidatesForBlank = <int>[];
      for (int i = 0; i < words.length; i++) {
        final clean = words[i].replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
        if (clean.length > 2) {
          candidatesForBlank.add(i);
        }
      }
      if (candidatesForBlank.isEmpty) continue;

      final blankIndex = candidatesForBlank[_random.nextInt(candidatesForBlank.length)];
      final answer = words[blankIndex].replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (answer.isEmpty) continue;

      final displayedWords = [...words];
      displayedWords[blankIndex] = '____';

      final wrongWords = wordPool
          .where((w) => w.toLowerCase() != answer.toLowerCase())
          .toList()
        ..shuffle(_random);

      final options = <String>[answer];
      for (final w in wrongWords) {
        if (!options.contains(w)) options.add(w);
        if (options.length == 4) break;
      }

      while (options.length < 4) {
        options.add(answer);
      }

      options.shuffle(_random);

      _items.add({
        'prompt': displayedWords.join(' '),
        'answer': answer,
        'options': options,
        'full': sentence,
      });
    }

    _order
      ..clear()
      ..addAll(List<int>.generate(_items.length, (index) => index));
  }

  void _choose(String option) {
    if (_selected != null || _finished) return;

    setState(() {
      _selected = option;
      final item = _items[_order[_current]];
      if (option.toLowerCase() == item['answer'].toString().toLowerCase()) {
        _score += 1;
      }
    });
  }

  void _next() {
    if (_selected == null) return;

    setState(() {
      if (_current >= _order.length - 1) {
        _finished = true;
        // Unlock the next reading task
        final currentTask = "Fill in the Blanks";
        final readingIndex = _categories.indexOf(currentTask);
        if (readingIndex >= 0) {
          final currentUnlocked = box.get('unlocked_reading_task_index');
          final unlocked = (currentUnlocked is num)
              ? currentUnlocked.toInt()
              : int.tryParse(currentUnlocked?.toString() ?? '') ?? 0;
          if (readingIndex >= unlocked) {
            final next = (readingIndex + 1).clamp(0, _categories.length - 1);
            box.put('unlocked_reading_task_index', next);
          }
        }
      } else {
        _current += 1;
        _selected = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dync = widget.dync;

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: dync.primary,
        appBar: AppBar(
          backgroundColor: dync.primary,
          foregroundColor: dync.onPrimary,
          title: const Text('Fill in the Blanks'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'No sentence data available yet for this exercise.',
              style: TextStyle(color: dync.onPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_finished) {
      return Scaffold(
        backgroundColor: dync.primary,
        appBar: AppBar(
          backgroundColor: dync.primary,
          foregroundColor: dync.onPrimary,
          title: const Text('Fill in the Blanks'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Completed!',
                style: TextStyle(
                  color: dync.onPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: $_score / ${_order.length}',
                style: TextStyle(color: dync.onPrimary, fontSize: 20),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Reading'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _items[_order[_current]];
    final prompt = item['prompt'].toString();
    final answer = item['answer'].toString();
    final options = (item['options'] as List).map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: dync.primary,
      appBar: AppBar(
        backgroundColor: dync.primary,
        foregroundColor: dync.onPrimary,
        title: const Text('Fill in the Blanks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${_current + 1} / ${_order.length}',
              style: TextStyle(
                color: dync.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dync.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                prompt,
                style: TextStyle(
                  color: dync.onPrimaryContainer,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...options.map((option) {
              Color? bg;
              if (_selected != null) {
                if (option.toLowerCase() == answer.toLowerCase()) {
                  bg = Colors.green;
                } else if (_selected == option) {
                  bg = Colors.red;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg ?? dync.onPrimaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _choose(option),
                  child: Text(option),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: _selected == null ? null : _next,
              child: Text(_current == _order.length - 1 ? 'Finish' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}
