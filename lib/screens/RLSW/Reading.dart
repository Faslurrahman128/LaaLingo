import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:LaaLingo/learning/progress.dart';
import 'package:LaaLingo/learning/learning.dart';
import 'package:LaaLingo/progress_brain.dart/progress.dart';
import 'package:LaaLingo/screens/RLSW/fill_in_blanks.dart';

class Reading extends StatefulWidget {
  late ColorScheme dync;
  Reading({required this.dync, super.key});

  @override
  State<Reading> createState() => _ReadingState();
}

class _ReadingState extends State<Reading> {
  progress prog = progress();
  final box = Hive.box('LocalDB');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.dync.primaryContainer,
      appBar: AppBar(
        backgroundColor: widget.dync.primary,
        foregroundColor: widget.dync.secondaryContainer,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: TopheadCLipper(),
            child: Container(
              child: Center(
                child: Text(
                  "Reading",
                  style: TextStyle(
                      color: widget.dync.secondaryContainer,
                      fontSize: 34,
                      fontWeight: FontWeight.bold),
                ),
              ),
              color: widget.dync.primary,
              height: MediaQuery.of(context).size.height / 3.5,
            ),
          ),
          Expanded(
            child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final rawUnlocked = box.get('unlocked_reading_task_index');
                  final unlockedIndex = (rawUnlocked is num)
                      ? rawUnlocked.toInt()
                      : int.tryParse(rawUnlocked?.toString() ?? '') ?? 0;
                  final isUnlocked = index <= unlockedIndex;

                  return GestureDetector(
                    onTap: () {
                      isUnlocked
                          ? {
                              categories[index] == 'Fill in the Blanks'
                                  ? Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FillInBlanksPage(
                                          dync: widget.dync,
                                        ),
                                      ),
                                    )
                                  : Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => questionsUi(
                                          topic: categories[index],
                                          dync: widget.dync,
                                        ),
                                      ),
                                    )
                            }
                          : {};
                    },
                    child: !isUnlocked
                        ? Stack(
                            children: [
                              Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: widget.dync.background,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30))),
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height / 10,
                                  child: Center(
                                    child: Text(
                                      categories[index],
                                      style: TextStyle(
                                          color: widget.dync.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17),
                                    ),
                                  )),
                              Opacity(
                                opacity: 0.9,
                                child: Container(
                                    margin: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: widget.dync.primary,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    width: double.infinity,
                                    height:
                                        MediaQuery.of(context).size.height / 10,
                                    child: Center(child: Icon(Icons.lock))),
                              ),
                            ],
                          )
                        : Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: widget.dync.primary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height / 10,
                            child: Center(
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                    color: widget.dync.secondaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                            )),
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class TopheadCLipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = new Path();

    path.lineTo(0.0, size.height - 40);

    path.quadraticBezierTo(
        size.width / 4, size.height - 80, size.width / 2, size.height - 40);

    path.quadraticBezierTo(size.width - (size.width / 4), size.height,
        size.width, size.height - 40);

    path.lineTo(size.width, 0.0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true; //if new instance have different instance than old instance
    //then you must return true;
  }
}

List<String> categories = [
  "Basic_Words",
  "Numbers",
  "Colors_Data",
  "Food_Data",
  "Animals_Data",
  "Vocabulary",
  "Everyday_Essentials",
  "Travel_Talk",
  "Grammar_and_Usage_Drill",
  "Phrases and Expressions",
  "Grammar",
  "Dialogues and Conversations",
  "Cultural Insights",
  "Fill in the Blanks",
];
