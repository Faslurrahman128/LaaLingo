import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class McqMatchPage extends StatefulWidget {
  final ColorScheme dync;
  const McqMatchPage({Key? key, required this.dync}) : super(key: key);

  @override
  State<McqMatchPage> createState() => _McqMatchPageState();
}

class _McqMatchPageState extends State<McqMatchPage> {
  int _currentQuestion = 0;
  int? _selectedIndex;
  bool _answered = false;
  int _score = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which word means "quickly"?',
      'options': ['Slowly', 'Rapidly', 'Lazily', 'Quietly'],
      'answer': 1,
      'type': 'Vocabulary',
    },
    {
      'question': 'Choose the correct plural: "child"',
      'options': ['childs', 'childes', 'children', 'child'],
      'answer': 2,
      'type': 'Grammar',
    },
    {
      'question': 'What is the synonym of "happy"?',
      'options': ['Sad', 'Joyful', 'Angry', 'Tired'],
      'answer': 1,
      'type': 'Vocabulary',
    },
    {
      'question': 'Which sentence is correct?',
      'options': ['She go to school.', 'She goes to school.', 'She going to school.', 'She gone to school.'],
      'answer': 1,
      'type': 'Grammar',
    },
    {
      'question': 'What is the antonym of "difficult"?',
      'options': ['Easy', 'Hard', 'Tough', 'Complicated'],
      'answer': 0,
      'type': 'Vocabulary',
    },
    {
      'question': 'Choose the correct form: "He ___ playing football."',
      'options': ['am', 'is', 'are', 'be'],
      'answer': 1,
      'type': 'Grammar',
    },
    {
      'question': 'Which word is a noun?',
      'options': ['Run', 'Beautiful', 'Happiness', 'Quickly'],
      'answer': 2,
      'type': 'Vocabulary',
    },
    {
      'question': 'Which is the correct past tense: "eat"?',
      'options': ['eated', 'ate', 'eats', 'eating'],
      'answer': 1,
      'type': 'Grammar',
    },
    {
      'question': 'What is the opposite of "begin"?',
      'options': ['Start', 'Open', 'Finish', 'Go'],
      'answer': 2,
      'type': 'Vocabulary',
    },
    {
      'question': 'Choose the correct article: "___ apple a day keeps the doctor away."',
      'options': ['A', 'An', 'The', 'No article'],
      'answer': 1,
      'type': 'Grammar',
    },
  ];

  void _onOptionTap(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _questions[_currentQuestion]['answer']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  void _finishQuiz() {
    // Unlock the next reading task using robust logic
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
    final currentTask = "MCQ/Match Exercise";
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
    // Return to the Reading page
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = _questions[_currentQuestion];
    final isLast = _currentQuestion == _questions.length - 1;
    return Scaffold(
      appBar: AppBar(title: const Text('MCQ Exercise'), backgroundColor: widget.dync.primary),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${current['type']} Question ${_currentQuestion + 1} of ${_questions.length}',
              style: TextStyle(fontSize: 16, color: widget.dync.secondary),
            ),
            const SizedBox(height: 12),
            Text(
              current['question'],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.dync.secondary),
            ),
            const SizedBox(height: 32),
            ...List.generate((current['options'] as List).length, (i) {
              Color borderColor = widget.dync.primary;
              Color? fillColor;
              if (_answered) {
                if (i == current['answer']) {
                  borderColor = Colors.green;
                  fillColor = Colors.green.withOpacity(0.1);
                } else if (_selectedIndex == i) {
                  borderColor = Colors.red;
                  fillColor = Colors.red.withOpacity(0.1);
                }
              }
              return GestureDetector(
                onTap: () => _onOptionTap(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fillColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    current['options'][i],
                    style: TextStyle(fontSize: 18, color: widget.dync.secondaryContainer),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            if (_answered)
              Column(
                children: [
                  Text(
                    _selectedIndex == current['answer']
                        ? 'Correct!'
                        : 'Incorrect. The answer is: ${current['options'][current['answer']]}',
                    style: TextStyle(
                      fontSize: 18,
                      color: _selectedIndex == current['answer'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (!isLast)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.dync.primary,
                        foregroundColor: widget.dync.secondaryContainer,
                      ),
                      onPressed: _nextQuestion,
                      child: const Text('Next'),
                    ),
                  if (isLast)
                    Column(
                      children: [
                        Text(
                          'Quiz Complete!\nYour Score: $_score / ${_questions.length}',
                          style: TextStyle(fontSize: 20, color: widget.dync.secondary, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.dync.primary,
                            foregroundColor: widget.dync.secondaryContainer,
                          ),
                          onPressed: _finishQuiz,
                          child: const Text('Back to Reading Exercises'),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
