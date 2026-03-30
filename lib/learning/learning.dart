import 'package:LaaLingo/screens/RLSW/Reading.dart';
import 'dart:convert';
import 'dart:math';

import 'package:LaaLingo/learning/progress.dart';
import 'package:LaaLingo/progress_brain.dart/progress.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:LaaLingo/supabase_langs.dart';

double height = 250;


class questionsUi extends StatefulWidget {
  final String topic;
  late ColorScheme dync;
  final List<String> categories;
  questionsUi({required this.topic, required this.dync, required this.categories});

  @override
  State<questionsUi> createState() => _questionsUiState();
}

class _questionsUiState extends State<questionsUi> {
  // Use categories from widget for unlock logic

  static const List<String> _quizTaskOrder = [
    "Basic_Words",
    "Numbers",
    "Colors_Data",
    "Food_Data",
    "Animals_Data",
    "Vocabulary",
    "Grammar",
    "Cultural Insights",
    "Phrases and Expressions",
    "Dialogues and Conversations",
  ];

  Color answer_opition = Colors.white;
  bool Popin_correct = false;
  bool Popin_incorrect = false;
  double Progress = 0;
  int _answeredCount = 0;
  int _correctCount = 0;
  late List Question;
  late List<List<dynamic>> _questionPairs;
  final List<int> _questionOrder = [];
  int _currentQuestionOrderPos = 0;
  String _currentPrompt = '';
  String _currentAnswer = '';
  List<String> _currentOptions = [];
  final Random _random = Random();
  final List<Map<String, String>> _mistakes = [];
  late String lang;
  late String lang_code;
  progress prog = progress();

  var box = Hive.box("LocalDB");
  FlutterTts flutterTts = FlutterTts();

  String? _initError;

  @override
  void initState() {
    print(box.get("Data_downloaded"));

    final q = box.get(widget.topic);
    if (q is List) {
      Question = q;
    } else {
      Question = [];
    }

    final userRow = box.get('Lang');
    final rawCurrent = box.get('current_lang');
    final currentLang = (rawCurrent is num)
      ? rawCurrent.toInt()
      : int.tryParse(rawCurrent?.toString() ?? '') ?? 1;

    final slot = getLangSlot(userRow, currentLang);
    final selected = slot?['Selected_lang'];
    if (selected is! List || selected.length < 2) {
      _initError = 'No language selected. Please go back and select a language.';
      super.initState();
      return;
    }

    lang = selected[0].toString();
    lang_code = selected[1].toString();

    final raw = box.get("Data_downloaded");
    final RawData = (raw is Map) ? raw.cast<dynamic, dynamic>() : <dynamic, dynamic>{};

    final temp = RawData[widget.topic];
    final TempU = (temp is List) ? temp : <dynamic>[];
    print(TempU);

    if (Question.length < 4 || TempU.length < 4) {
      _initError = 'Missing learning data for "${widget.topic}". Please go back and try downloading again.';
      super.initState();
      return;
    }

    final pairCount = min(Question.length, TempU.length);
    _questionPairs = <List<dynamic>>[];
    for (var i = 0; i < pairCount; i++) {
      _questionPairs.add([TempU[i], Question[i]]);
    }

    if (_questionPairs.length < 4) {
      _initError = 'Need at least 4 unique questions for "${widget.topic}".';
      super.initState();
      return;
    }

    _questionOrder
      ..clear()
      ..addAll(List<int>.generate(_questionPairs.length, (index) => index))
      ..shuffle(_random);
    _prepareCurrentQuestion();
    super.initState();
  }

  void _prepareCurrentQuestion() {
    if (_questionOrder.isEmpty) return;

    if (_currentQuestionOrderPos >= _questionOrder.length) {
      _questionOrder.shuffle(_random);
      _currentQuestionOrderPos = 0;
    }

    final currentPairIndex = _questionOrder[_currentQuestionOrderPos];
    final currentPair = _questionPairs[currentPairIndex];
    _currentPrompt = currentPair[0].toString();
    _currentAnswer = currentPair[1].toString();

    final distractorIndices = List<int>.generate(_questionPairs.length, (i) => i)
      ..remove(currentPairIndex)
      ..shuffle(_random);

    final options = <String>[_currentAnswer];

    for (final idx in distractorIndices) {
      final candidate = _questionPairs[idx][1].toString();
      if (!options.contains(candidate)) {
        options.add(candidate);
      }
      if (options.length == 4) break;
    }

    for (final idx in distractorIndices) {
      if (options.length == 4) break;
      options.add(_questionPairs[idx][1].toString());
    }

    _currentOptions = options.take(4).toList()..shuffle(_random);
  }

  void _goToNextQuestion() {
    _currentQuestionOrderPos += 1;
    _prepareCurrentQuestion();
  }

  void _unlockNextTaskAfterCompletion() {
    final currentTopic = widget.topic;
    final categories = widget.categories;
    final readingIndex = categories.indexOf(currentTopic);
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

    final quizIndex = _quizTaskOrder.indexOf(currentTopic);
    if (quizIndex >= 0) {
      final currentUnlocked = box.get('unlocked_quiz_task_index');
      final unlocked = (currentUnlocked is num)
          ? currentUnlocked.toInt()
          : int.tryParse(currentUnlocked?.toString() ?? '') ?? 0;
      if (quizIndex >= unlocked) {
        final next = (quizIndex + 1).clamp(0, _quizTaskOrder.length - 1);
        box.put('unlocked_quiz_task_index', next);
      }
    }
  }

  Future<void> _showQuizSummary() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Quiz summary'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Answered: $_answeredCount'),
                Text('Correct: $_correctCount'),
                Text('Accuracy: ${_answeredCount == 0 ? 0 : ((_correctCount / _answeredCount) * 100).round()}%'),
                if (_mistakes.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'Review mistakes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ..._mistakes.take(5).map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${m['prompt']} → ${m['answer']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    if (_initError != null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: widget.dync.primary,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _initError!,
                style: TextStyle(color: widget.dync.onPrimary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: widget.dync.primary,
        body: Stack(children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 17,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back_ios_new_sharp)),
                    LinearPercentIndicator(
                      progressColor: Colors.black,
                      percent: Progress,
                      width: MediaQuery.of(context).size.width / 1.5,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_correctCount/5',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'A:$_answeredCount',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: Text(
                      "$_currentPrompt in $lang",
                      style: TextStyle(fontSize: 20),
                    )),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 10,
                    ),
                    GestureDetector(
                      onTap: () async {
                        flutterTts.setLanguage(trcode[lang_code].toString());

                        flutterTts.speak(_currentAnswer);
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: widget.dync.primaryContainer,
                            borderRadius:
                                BorderRadius.all(Radius.circular(30))),
                        child: Icon(
                          Icons.audio_file,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
                flex: 2,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      for (final option in _currentOptions) AnswerOptions(option),
                    ],
                  ),
                ),
                flex: 2,
              )
            ],
          ),
          Incorrect(context),
          correct(context)
        ]),
      ),
    );
  }

  Visibility Incorrect(BuildContext context) {
    return Visibility(
      visible: Popin_incorrect,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: Duration(seconds: 2),
          height: MediaQuery.of(context).size.height / 4,
          width: double.infinity,
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Incorrect",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Correct Answer",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _currentAnswer,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _goToNextQuestion();
                      Popin_incorrect = false;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(0),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
                    child: Text(
                      "Got it",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Visibility correct(BuildContext context) {
    return Visibility(
      visible: Popin_correct,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height / 4,
          width: double.infinity,
          color: Colors.green,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  " Awesome!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () async {
                    final shouldFinish = Progress > 0.8;
                    if (!shouldFinish) {
                      setState(() {
                        _goToNextQuestion();
                        Popin_correct = false;
                        Progress += 0.2;
                      });
                      return;
                    }

                    setState(() {
                      Popin_correct = false;
                    });

                    await _showQuizSummary();
                    if (!mounted) return;

                    _unlockNextTaskAfterCompletion();
                    prog.progress_update(0);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => Reading(dync: widget.dync),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.all(0),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.white,
                    ),
                    child: Text(
                      "CONTINUE",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Expanded AnswerOptions(String value) {
    return Expanded(
        child: GestureDetector(
      onTap: () {
        if (Popin_correct || Popin_incorrect) return;

        final prompt = _currentPrompt;
        _answeredCount += 1;

        if (value == _currentAnswer) {
          setState(() {
            _correctCount += 1;
            Popin_correct = true;
          });
        } else {
          setState(() {
            _mistakes.add({
              'prompt': prompt,
              'picked': value,
              'answer': _currentAnswer,
            });
            Popin_incorrect = true;
          });
        }
      },
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
            color: widget.dync.primaryContainer,
            border: Border.all(color: widget.dync.onPrimary),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Center(
            child: Text(
          value,
          style: TextStyle(
              color: widget.dync.secondary,
              fontSize: 15,
              fontWeight: FontWeight.bold),
        )),
      ),
    ));
  }
}

Map<String, String> trcode = {
  "hr": "hr-HR",
  "ko": "ko-KR",
  "mr": "mr-IN",
  "ru": "ru-RU",
  "zh": "zh-TW",
  "hu": "hu-HU",
  "sw": "sw-KE",
  "th": "th-TH",
  "en": "en-US",
  "hi": "hi-IN",
  "fr": "fr-FR",
  "ja": "ja-JP",
  "ta": "ta-IN",
  "ro": "ro-RO"
};
