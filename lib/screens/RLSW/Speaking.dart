import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:LaaLingo/learning/speakinglearning.dart';
import 'package:LaaLingo/progress_brain.dart/progress.dart';

class Speaking extends StatefulWidget {
  late ColorScheme dync;
  Speaking({required this.dync, super.key});

  @override
  State<Speaking> createState() => _SpeakingState();
}

class _SpeakingState extends State<Speaking> {
    // Remove unlocked from state, will load in build
  List<String> speakingcatg = [];
  progress prog = progress();

  @override
  void initState() {
    var box = Hive.box("LocalDB");
    var speakingRaw = box.get("SPEAKING");
    if (speakingRaw != null && speakingRaw is Map) {
      Map Speaking = speakingRaw;
      Speaking.forEach((key, value) {
        speakingcatg.add(key);
      });
    }
    // Always unlock the first exercise if nothing is unlocked
    List unlocked = box.get('unlocked_speech_tests') ?? [];
    if (unlocked.isEmpty && speakingcatg.isNotEmpty) {
      unlocked.add(speakingcatg[0]);
      box.put('unlocked_speech_tests', unlocked);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Always get the latest unlocked list from Hive
    var box = Hive.box("LocalDB");
    List unlocked = box.get('unlocked_speech_tests') ?? [];
    return Scaffold(
      backgroundColor: widget.dync.primaryContainer,
      appBar: AppBar(
        backgroundColor: widget.dync.primary,
        foregroundColor: widget.dync.primaryContainer,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipPath(
            clipper: TopheadCLipper(),
            child: Container(
              child: Center(
                child: Text(
                  "Speaking",
                  style: TextStyle(
                      color: widget.dync.primaryContainer,
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
                itemCount: speakingcatg.length,
                itemBuilder: (context, index) {
                  bool isUnlocked = unlocked.contains(speakingcatg[index]);
                  return GestureDetector(
                    onTap: () async {
                      if (isUnlocked) {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SpeakingLearning(
                                  cat: speakingcatg[index],
                                  dync: widget.dync,
                                  allCats: speakingcatg,
                                )));
                        setState(() {}); // Refresh to show new unlocks
                      }
                    },
                    child: isUnlocked
                        ? Container(
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: widget.dync.primary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height / 10,
                            child: Center(
                              child: Text(
                                speakingcatg[index],
                                style: TextStyle(
                                    color: widget.dync.secondaryContainer,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        : Stack(
                            children: [
                              Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: widget.dync.primary,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height / 10,
                                  child: Center(
                                    child: Text(
                                      speakingcatg[index],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: widget.dync.primaryContainer,
                                          fontSize: 18),
                                    ),
                                  )),
                              Opacity(
                                opacity: 0.8,
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
                          ),
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
