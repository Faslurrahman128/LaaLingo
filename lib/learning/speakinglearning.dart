import 'dart:collection';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:LaaLingo/progress_brain.dart/progress.dart';
import 'package:LaaLingo/screens/RLSW/Speaking.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:translator/translator.dart';
import 'package:LaaLingo/supabase_langs.dart';
import '../utils/pronunciation_evaluator.dart';
import '../utils/gamification.dart';

class SpeakingLearning extends StatefulWidget {
  late String cat;
  late ColorScheme dync;
  final List<String> allCats;
  SpeakingLearning({required this.cat, required this.dync, required this.allCats});

  @override
  State<SpeakingLearning> createState() => _SpeakingLearningState();
}

class _SpeakingLearningState extends State<SpeakingLearning> {
  void _unlockNextSpeechTest() {
    var box = Hive.box("LocalDB");
    final unlocked = box.get('unlocked_speech_tests') ?? <String>[];
    // Always ensure current is unlocked
    if (!unlocked.contains(widget.cat)) {
      unlocked.add(widget.cat);
    }
    // Unlock the next exercise if available, using the passed allCats list
    int idx = widget.allCats.indexOf(widget.cat);
    if (idx != -1 && idx + 1 < widget.allCats.length) {
      String nextCat = widget.allCats[idx + 1];
      if (!unlocked.contains(nextCat)) {
        unlocked.add(nextCat);
      }
    }
    box.put('unlocked_speech_tests', unlocked);
  }
      // Unlock the next speech test (implement your own logic as needed)
    int _pronunciationScore = 0;
    String _pronunciationFeedback = '';

  double Progress = 0;
  List Questions = [];
  FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";
  final TextEditingController _textController = TextEditingController();
  final translator = GoogleTranslator();

  Gamification gamification = Gamification();
  int x = 0;
  bool islist = false;
  late String lang_code;
  progress prog = progress();

  @override
  void initState() {
    var box = Hive.box("LocalDB");
    final userRow = box.get('Lang');
    final rawCurrent = box.get('current_lang');
    final currentLang = (rawCurrent is num)
      ? rawCurrent.toInt()
      : int.tryParse(rawCurrent?.toString() ?? '') ?? 1;
    final slot = getLangSlot(userRow, currentLang);
    final selected = slot?['Selected_lang'];
    lang_code = (selected is List && selected.length >= 2)
      ? selected[1].toString()
      : 'en';
    List QuestionRawData = box.get(widget.cat);
    List QuestionRawDataUn = box.get('SPEAKING')[widget.cat];
    var pos = 0;

    QuestionRawDataUn.forEach((element) {
      Questions.add([element, QuestionRawData[pos++]]);
    });

    super.initState();
    listenForPermissions();
    if (!_speechEnabled) {
      _initSpeech();
    }
  }

  void listenForPermissions() async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        print(status);
        requestForPermission();
        break;
      case PermissionStatus.granted:
        break;
      case PermissionStatus.limited:
        break;
      case PermissionStatus.permanentlyDenied:
        break;
      case PermissionStatus.restricted:
        break;
      case PermissionStatus.provisional:
        // TODO: Handle this case.
        print("default");
        break;
    }
  }

  Future<void> requestForPermission() async {
    PermissionStatus x = await Permission.microphone.request();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  void _startListening() async {
    setState(() {
      _lastWords = "";
      _textController.text = "";
      _pronunciationScore = 0;
      _pronunciationFeedback = '';
    });
    _speechToText.initialize();
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      localeId: trcode[lang_code].toString(),
      cancelOnError: false,
      partialResults: false,
      listenMode: ListenMode.dictation,
    );
    print(_speechToText.isListening);
  }

  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }


  void _onSpeechResult(SpeechRecognitionResult result) {
    // Only use the latest recognized result, do not append
    _lastWords = result.recognizedWords;


    String normalize(String s) {
      // Lowercase, remove punctuation, normalize spaces, treat hyphens as spaces
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'[-_]'), ' ')
          .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    final expectedRaw = Questions[x][1];
    final recognizedRaw = _lastWords;
    final expected = normalize(expectedRaw);
    final recognized = normalize(recognizedRaw);
    // Evaluate pronunciation
    final eval = PronunciationEvaluator.evaluate(recognized, expected);
    _pronunciationScore = eval['score'];
    // Feedback message
    String feedbackMsg = '';
    if (_pronunciationScore == 100) {
      feedbackMsg = '🎉 Perfect! 100%';
    } else if (_pronunciationScore >= 80) {
      feedbackMsg = 'Good! Minor mistake. $_pronunciationScore%\nExpected: "$expectedRaw"\nYour answer: "$recognizedRaw"';
    } else {
      feedbackMsg = 'Try again. $_pronunciationScore%\nExpected: "$expectedRaw"\nYour answer: "$recognizedRaw"';
    }

    if (!mounted) return;

    setState(() {
      _textController.text = _lastWords;
      _pronunciationFeedback = feedbackMsg;
    });

    if (_pronunciationScore < 100) {
      // Show feedback and mistake, do not advance
      return;
    }

    // If last exercise, show finish message, unlock next test, and navigate back
    if (Progress >= 0.8) {
      setState(() {
        _pronunciationFeedback = '🏁 Congratulations! You\'ve finished this exercise!';
      });
      // Update progress in Supabase and unlock next speech test if needed
      prog.progress_update(2);
      // Unlock next speech test (example: set a flag in Hive or call a method)
      _unlockNextSpeechTest();
      // After a short delay, navigate back to Speaking page
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return;
    }

    // Show perfect/good message, then advance after a short delay
    setState(() {
      _pronunciationFeedback = '🎉 Perfect! 100%';
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        x += 1;
        Progress += 0.2;
        _lastWords = "";
        _textController.text = "";
        _pronunciationScore = 0;
        _pronunciationFeedback = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: widget.dync.primary,
        body: Stack(children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Padding(
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
                      Icon(Icons.report)
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Column(
                  children: [
                    Text(
                      Questions[x][0],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: widget.dync.onPrimary),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      Questions[x][1],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: widget.dync.primaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.normal),
                    )
                  ],
                ),
              ),
              Container(
                height: 150,
                color: widget.dync.primary,
                padding: EdgeInsets.all(16),
                child: TextField(
                  enabled: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, color: Colors.red),
                  controller: _textController,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: widget.dync.primary,
                  ),
                ),
              ),
              // Show pronunciation feedback only if available
              if (_pronunciationFeedback.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _pronunciationFeedback,
                    style: TextStyle(
                      fontSize: 18,
                      color: _pronunciationScore == 100
                          ? Colors.green
                          : (_pronunciationScore >= 80 ? Colors.orange : Colors.red),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Container(
                  child: Text(Questions[x][0],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold))),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        print(trcode[lang_code].toString());
                        flutterTts.setLanguage(trcode[lang_code].toString());
                        flutterTts.speak(Questions[x][1]);
                      },
                      child: Container(
                        margin: EdgeInsets.all(15),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: widget.dync.primaryContainer,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: Icon(
                          Icons.speaker,
                          color: widget.dync.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          islist = islist ? false : true;
                          if (!islist) {
                            _stopListening();
                          } else {
                            _textController.text = "";
                            _startListening();
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.all(15),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: widget.dync.primaryContainer,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: Icon(
                          islist ? Icons.cancel : Icons.mic,
                          color: widget.dync.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ]),
      ),
    );
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

bool custom_compare(String ques, String ans) {
  print("compare");
  int count = 0;
  print(ques);
  bool con = false;
  for (int i = 0; i < ans.length; i++) {
    if (ques.contains(ans[i])) {
      count++;
    }
    if (count > ques.length - 4) {
      con = true;
    }
  }
  return con;
}
