// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LaaLingo/chatroom/chartui.dart';

class leaderboard extends StatefulWidget {
  late ColorScheme dync;
  leaderboard({required this.dync, super.key});

  @override
  State<leaderboard> createState() => _leaderboardState();
}


const List<Color> rank_colors = [
  Color.fromARGB(255, 241, 186, 20),
  Color.fromARGB(255, 231, 205, 205),
  Colors.brown,
  Colors.white
];

class _leaderboardState extends State<leaderboard> {
  @override
  void initState() {
    super.initState();
    print("Leaderboard loaded");
    userEmail = Supabase.instance.client.auth.currentUser?.email;
  }

  @override
  void dispose() {
    super.dispose();
  }
  String? userEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height / 10,
          child: Center(
            child: Text(
              "Leaderboard",
              style: TextStyle(
                fontSize: 34,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('user')
                .stream(primaryKey: ['email'])
                .order('leader_board', ascending: false),
            builder: (context, snapshot) {
              print('Leaderboard snapshot: data=${snapshot.data}, error=${snapshot.error}, connectionState=${snapshot.connectionState}');
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: \\${snapshot.error}\\",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Text(
                    "Loading ..",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                return const Center(
                  child: Text(
                    "No leaderboard entries yet!",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final data = snapshot.data!;
              List udata = data;

              final meEmail = userEmail?.toLowerCase();
              int? myIndex;
              dynamic myRow;
              if (meEmail != null && meEmail.isNotEmpty) {
                for (var i = 0; i < udata.length; i++) {
                  final row = udata[i];
                  final rowEmail = (row is Map) ? row['email']?.toString().toLowerCase() : null;
                  if (rowEmail != null && rowEmail == meEmail) {
                    myIndex = i;
                    myRow = row;
                    break;
                  }
                }
              }

              final showPinnedMe = myIndex != null && myRow is Map;

              // If we show a pinned "(You)" row, remove the user's normal row from the
              // scrolling list to avoid duplicates. Keep each row's original index so
              // rank numbers stay correct.
              final visibleRows = <MapEntry<int, dynamic>>[];
              for (var i = 0; i < udata.length; i++) {
                if (showPinnedMe && myIndex != null && i == myIndex) continue;
                visibleRows.add(MapEntry(i, udata[i]));
              }

              return Column(
                children: [
                  if (showPinnedMe) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: leadcont(
                        status: Colors.transparent,
                        currentUserEmail: userEmail,
                        name: '${(myRow as Map)['name'] ?? 'You'} (You)',
                        email: (myRow as Map)['email']?.toString() ?? '',
                        dync: widget.dync,
                        imageurl: (myRow as Map)['avtar_url'],
                        index: myIndex!,
                        shield: rank_colors[myIndex! < 3 ? myIndex! : 3],
                        context: context,
                        points: (myRow as Map)['leader_board'],
                      ),
                    ),
                  ],
                  Expanded(
                    child: ListView.builder(
                      itemCount: visibleRows.length,
                      itemBuilder: (context, index) {
                        final entry = visibleRows[index];
                        final originalIndex = entry.key;
                        final userData = entry.value;
                        final rowEmail = userData["email"]?.toString() ?? '';
                        final isMe = meEmail != null && rowEmail.toLowerCase() == meEmail;

                        return leadcont(
                          status: userData["status"] == true
                              ? (isMe ? Colors.transparent : Colors.green)
                              : Colors.transparent,
                          currentUserEmail: userEmail,
                          name: userData["name"],
                          email: rowEmail,
                          dync: widget.dync,
                          imageurl: userData['avtar_url'],
                          index: originalIndex,
                          shield: rank_colors[originalIndex < 3 ? originalIndex : 3],
                          context: context,
                          points: userData["leader_board"],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// Supabase returns sorted data, so no need for sort_data

GestureDetector leadcont({
  required String? currentUserEmail,
  required name,
  required String email,
  required ColorScheme dync,
  required imageurl,
  required int index,
  required Color shield,
  required BuildContext context,
  required points,
  required Color status,
}) {
  final meEmail = currentUserEmail?.toLowerCase();
  final isMe = meEmail != null && meEmail.isNotEmpty && email.toLowerCase() == meEmail;

  return GestureDetector(
    onTap: () {
      (isMe)
          ? {}
          : Navigator.of(context).push(MaterialPageRoute(builder: ((context) {
              return chatUI(
                  reciver: name.toString().toLowerCase(),
                  reciver_name: name,
                  dync: dync);
            })));
    },
    child: Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isMe)
            ? dync.primaryContainer
            : Colors.white,
        border: Border.all(
          color: (!isMe)
              ? dync.primaryContainer
              : Colors.white,
          width: 3,
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            index < 3
                ? Container(
                    height: MediaQuery.of(context).size.height / 25,
                    width: MediaQuery.of(context).size.width / 13,
                    child: Icon(
                      Icons.shield,
                      color: shield,
                    ),
                  )
                : Container(
                    height: MediaQuery.of(context).size.height / 25,
                    width: MediaQuery.of(context).size.width / 10,
                    child: Center(
                        child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: dync.primary),
                    )),
                  ),
            Stack(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                    child: (imageurl == null || imageurl.toString().trim().isEmpty)
                        ? Container(
                            color: dync.primaryContainer,
                            child: Icon(
                              Icons.person,
                              color: dync.onPrimaryContainer,
                              size: 24,
                            ),
                          )
                        : Image.network(
                            imageurl.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: dync.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: dync.onPrimaryContainer,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                      color: status,
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                )
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.6,
              height: MediaQuery.of(context).size.width / 14,
              child: Text(
                name,
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: dync.primary, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              child: Text(
                'Level ${points.toString()}',
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: dync.primary, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    ),
  );
}
