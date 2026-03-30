import 'package:flutter/material.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class ImageBasedQuestionsPage extends StatefulWidget {
  final ColorScheme dync;
  const ImageBasedQuestionsPage({required this.dync, super.key});

  @override
  State<ImageBasedQuestionsPage> createState() => _ImageBasedQuestionsPageState();
}

class _ImageBasedQuestionsPageState extends State<ImageBasedQuestionsPage> {
  final List<Map<String, dynamic>> _questions = [
    {
      'image': 'assets/puzzle_school.png',
      'answer': 'school',
      'options': ['school', 'teacher', 'library', 'chalk'],
    },
    {
      'image': 'assets/puzzle_teacher.png',
      'answer': 'teacher',
      'options': ['student', 'teacher', 'notebook', 'uniform'],
    },
    {
      'image': 'assets/puzzle_pencil.png',
      'answer': 'pencil',
      'options': ['pencil', 'chalk', 'classroom', 'subject'],
    },
    {
      'image': 'assets/puzzle_library.png',
      'answer': 'library',
      'options': ['library', 'school', 'notebook', 'student'],
    },
    {
      'image': 'assets/puzzle_classroom.png',
      'answer': 'classroom',
      'options': ['classroom', 'teacher', 'uniform', 'chalk'],
    },
    {
      'image': 'assets/puzzle_notebook.png',
      'answer': 'notebook',
      'options': ['notebook', 'library', 'school', 'subject'],
    },
    {
      'image': 'assets/puzzle_student.png',
      'answer': 'student',
      'options': ['student', 'teacher', 'chalk', 'pencil'],
    },
    {
      'image': 'assets/puzzle_subject.png',
      'answer': 'subject',
      'options': ['subject', 'notebook', 'classroom', 'uniform'],
    },
    {
      'image': 'assets/puzzle_uniform.png',
      'answer': 'uniform',
      'options': ['uniform', 'school', 'teacher', 'library'],
    },
    {
      'image': 'assets/puzzle_chalk.png',
      'answer': 'chalk',
      'options': ['chalk', 'pencil', 'notebook', 'student'],
    },
  ];

  int _currentIndex = 0;
  String? _selected;
  bool _showResult = false;
  bool _isCorrect = false;
  final _random = Random();

  void _selectOption(String option) {
    setState(() {
      _selected = option;
      _showResult = true;
      _isCorrect = option == _questions[_currentIndex]['answer'];
    });
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      // Unlock the next reading task
      final box = Hive.box('LocalDB');
      final List<String> categories = [
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
      final currentTask = "Image Based Questions";
      final readingIndex = categories.indexOf(currentTask);
      if (readingIndex >= 0) {
        final currentUnlocked = box.get('unlocked_reading_task_index');
        final unlocked = (currentUnlocked is num)
            ? currentUnlocked.toInt()
            : int.tryParse(currentUnlocked?.toString() ?? '') ?? 0;
        if (readingIndex >= unlocked) {
          final next = (readingIndex + 1).clamp(0, categories.length - 1);
          box.put('unlocked_reading_task_index', next);
        }
      }
      // Return to Reading page
      Navigator.of(context).pop();
    } else {
      setState(() {
        _currentIndex++;
        _selected = null;
        _showResult = false;
        _isCorrect = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dync = widget.dync;
    final q = _questions[_currentIndex];
    final options = List<String>.from(q['options']);
    options.shuffle(_random);
    return Scaffold(
      appBar: AppBar(title: Text('Image Based Questions'), backgroundColor: dync.primary),
      body: Center(
        child: _currentIndex < _questions.length
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    child: Image.asset(
                      q['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text('What is this?', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 18),
                  for (final option in options)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 32),
                      child: ElevatedButton(
                        onPressed: _showResult ? null : () => _selectOption(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selected == option
                              ? (_isCorrect ? Colors.green : Colors.red)
                              : dync.primary,
                          foregroundColor: dync.onPrimary,
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(option, style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  if (_showResult)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _isCorrect ? 'Correct!' : 'Try Again',
                        style: TextStyle(
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (_showResult && _isCorrect)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        child: Text(_currentIndex == _questions.length - 1 ? 'Finish' : 'Next'),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('All image questions completed!', style: TextStyle(fontSize: 22)),
                  SizedBox(height: 24),
                  Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                ],
              ),
      ),
    );
  }
}
