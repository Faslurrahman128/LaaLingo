import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

class PuzzlesExercisePage extends StatefulWidget {
  final ColorScheme dync;
  PuzzlesExercisePage({required this.dync, super.key});

  @override
  State<PuzzlesExercisePage> createState() => _PuzzlesExercisePageState();
}

class _PuzzlesExercisePageState extends State<PuzzlesExercisePage> {
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


  final List<String> _words = [
    "school",
    "teacher",
    "student",
    "classroom",
    "pencil",
    "notebook",
    "library",
    "subject",
    "uniform",
    "chalk",
  ];

  final List<String> _imagePaths = [
    "assets/puzzle_school.png",     // school
    "assets/puzzle_teacher.png",   // teacher
    "assets/puzzle_student.png",   // student
    "assets/puzzle_classroom.png", // classroom
    "assets/puzzle_pencil.png",    // pencil
    "assets/puzzle_notebook.png",  // notebook
    "assets/puzzle_library.png",   // library
    "assets/puzzle_subject.png",   // subject
    "assets/puzzle_uniform.png",   // uniform
    "assets/puzzle_chalk.png",     // chalk
  ];
  int _currentIndex = 0;
  List<String> _scrambledLetters = [];
  List<String> _selectedLetters = [];
  bool _showResult = false;
  bool _isCorrect = false;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _resetPuzzle();
  }

  void _resetPuzzle() {
    final word = _words[_currentIndex];
    _scrambledLetters = word.split('');
    do {
      _scrambledLetters.shuffle(_random);
    } while (_scrambledLetters.join() == word); // Ensure not in order
    _selectedLetters = [];
    _showResult = false;
    _isCorrect = false;
    setState(() {});
  }

  void _onLetterTap(int idx) {
    setState(() {
      _selectedLetters.add(_scrambledLetters[idx]);
      _scrambledLetters[idx] = '';
    });
  }

  void _onBackspace() {
    if (_selectedLetters.isNotEmpty) {
      setState(() {
        // Find first empty slot in scrambled and put back
        final letter = _selectedLetters.removeLast();
        for (int i = 0; i < _scrambledLetters.length; i++) {
          if (_scrambledLetters[i] == '') {
            _scrambledLetters[i] = letter;
            break;
          }
        }
      });
    }
  }

  void _checkAnswer() {
    final answer = _selectedLetters.join().toLowerCase();
    final correct = _words[_currentIndex];
    setState(() {
      _showResult = true;
      _isCorrect = answer == correct;
    });
  }

  void _nextPuzzle() {
    setState(() {
      _currentIndex++;
      if (_currentIndex < _words.length) {
        _resetPuzzle();
      } else {
        _unlockNextTask();
      }
    });
  }

  void _unlockNextTask() {
    final box = Hive.box('LocalDB');
    final currentTask = "Puzzles Exercise";
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dync = widget.dync;
    return Scaffold(
      appBar: AppBar(title: Text('Puzzles Exercise'), backgroundColor: dync.primary),
      body: Center(
        child: _currentIndex < _words.length
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Show image for the current word
                  SizedBox(
                    height: 120,
                    child: _imagePaths[_currentIndex] != null
                        ? Image.asset(
                            _imagePaths[_currentIndex],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                          )
                        : Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Text('Tap the letters in order to form the word:', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < _scrambledLetters.length; i++)
                        _scrambledLetters[i] != ''
                            ? ElevatedButton(
                                onPressed: _showResult ? null : () => _onLetterTap(i),
                                child: Text(_scrambledLetters[i], style: TextStyle(fontSize: 22)),
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(18),
                                  backgroundColor: dync.primary,
                                  foregroundColor: dync.onPrimary,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: null,
                                child: Text(
                                  _selectedLetters.length > 0 && i < _selectedLetters.length
                                      ? _selectedLetters[i]
                                      : '',
                                  style: TextStyle(fontSize: 22, color: Colors.grey),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(18),
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.grey,
                                ),
                              ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _scrambledLetters.length; i++)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          width: 40,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: i < _selectedLetters.length && _selectedLetters[i] != ''
                              ? Text(
                                  _selectedLetters[i],
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                      if (_selectedLetters.isNotEmpty && !_showResult)
                        IconButton(
                          icon: Icon(Icons.backspace),
                          onPressed: _onBackspace,
                        ),
                    ],
                  ),
                  SizedBox(height: 18),
                  if (_selectedLetters.length == _scrambledLetters.length && !_showResult)
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      child: Text('Check'),
                    ),
                  if (_showResult)
                    Column(
                      children: [
                        Text(_isCorrect ? 'Perfect Match!' : 'Try Again',
                            style: TextStyle(
                                color: _isCorrect ? Colors.green : Colors.red,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        if (_isCorrect)
                          ElevatedButton(
                            onPressed: _nextPuzzle,
                            child: Text(_currentIndex == _words.length - 1 ? 'Finish' : 'Next'),
                          ),
                        if (!_isCorrect)
                          ElevatedButton(
                            onPressed: _resetPuzzle,
                            child: Text('Retry'),
                          ),
                      ],
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('All puzzles completed!', style: TextStyle(fontSize: 22)),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _unlockNextTask,
                    child: Text('Back to Reading'),
                  ),
                ],
              ),
      ),
    );
  }
}
