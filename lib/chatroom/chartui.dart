import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LaaLingo/chatroom/chatbrain.dart';
import 'package:LaaLingo/chatroom/message.dart';
import 'package:timeago/timeago.dart' as timeago;

class chatUI extends StatefulWidget {
  late String reciver;
  late ColorScheme dync;
  late String reciver_name;

  chatUI(
      {required this.reciver,
      required this.dync,
      required this.reciver_name,
      super.key});

  @override
  State<chatUI> createState() => _chatUIState();
}

class _chatUIState extends State<chatUI> {
  late chatbrain brain;
  late String sender;

  final TextEditingController messagefield = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _pendingMessages = <Map<String, dynamic>>[];
  final Map<String, DateTime> _recentSendFingerprints = <String, DateTime>{};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    sender = Supabase.instance.client.auth.currentUser?.email ?? 'anonymous';
    brain = chatbrain(sender: sender, reciver: widget.reciver);
  }

  @override
  void dispose() {
    messagefield.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  DateTime? _tryParseTs(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  bool _sameMessage(Map<String, dynamic> serverRow, Map<String, dynamic> pendingRow) {
    final serverSender = (serverRow['sender'] ?? '').toString().toLowerCase();
    final pendingSender = (pendingRow['sender'] ?? '').toString().toLowerCase();
    if (serverSender != pendingSender) return false;

    final serverMessage = (serverRow['message'] ?? '').toString();
    final pendingMessage = (pendingRow['message'] ?? '').toString();
    if (serverMessage != pendingMessage) return false;

    final serverTs = _tryParseTs(serverRow['timestamp']);
    final pendingTs = _tryParseTs(pendingRow['timestamp']);
    if (serverTs == null || pendingTs == null) return true;

    final delta = serverTs.difference(pendingTs).inSeconds.abs();
    return delta <= 5;
  }

  String _fingerprint(Map<String, dynamic> row) {
    final rowSender = (row['sender'] ?? '').toString().trim().toLowerCase();
    final rowReciver = (row['reciver'] ?? '').toString().trim().toLowerCase();
    final rowMessage = (row['message'] ?? '').toString().trim();
    final rowId = row['id']?.toString().trim() ?? '';

    final ts = _tryParseTs(row['timestamp']);
    final tsSecond = ts == null
        ? ((row['timestamp'] ?? '').toString())
        : ts.millisecondsSinceEpoch ~/ 1000;

    if (rowId.isNotEmpty) {
      return 'id:$rowId';
    }

    return '$rowSender|$rowReciver|$rowMessage|$tsSecond';
  }

  List<Map<String, dynamic>> _dedupeMessages(List<Map<String, dynamic>> rows) {
    final unique = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final key = _fingerprint(row);
      unique[key] = row;
    }

    return unique.values.toList(growable: false);
  }

  Future<void> _handleSend() async {
    final text = messagefield.text.trim();
    if (text.isEmpty || _sending) return;

    final now = DateTime.now();
    _recentSendFingerprints.removeWhere(
      (_, sentAt) => now.difference(sentAt).inSeconds > 10,
    );

    final sendKey = '${sender.toLowerCase()}|${widget.reciver.toLowerCase()}|$text';
    final lastSentAt = _recentSendFingerprints[sendKey];
    if (lastSentAt != null && now.difference(lastSentAt).inMilliseconds < 1500) {
      return;
    }
    _recentSendFingerprints[sendKey] = now;

    final ts = DateTime.now().toIso8601String();
    final optimistic = <String, dynamic>{
      'sender': sender,
      'reciver': widget.reciver,
      'message': text,
      'timestamp': ts,
    };

    setState(() {
      _sending = true;
      _pendingMessages.add(optimistic);
    });

    messagefield.clear();
    _scrollToBottomSoon();

    try {
      final msg = message(
        sender: sender,
        reciver: widget.reciver,
        msg: text,
      );
      final payload = msg.getFmsg();
      payload['TimeStamp'] = ts;
      await brain.sendmessage(payload);
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((m) => m['timestamp'] == ts);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.dync.onPrimaryContainer,
        title: Text(widget.reciver_name),
      ),
      backgroundColor: widget.dync.primary,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: brain.recivemessage(),
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? const <Map<String, dynamic>>[];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      rows.isEmpty &&
                      _pendingMessages.isEmpty) {
                    return Text("Loading ..");
                  }
                  if (snapshot.hasError && rows.isEmpty && _pendingMessages.isEmpty) {
                    return Text("Error occured pls try later ..");
                  }

                  // Reconcile optimistic messages once they appear in the stream.
                  final pendingFiltered = _pendingMessages.where((m) {
                    for (final row in rows) {
                      if (_sameMessage(row, m)) {
                        return false;
                      }
                    }
                    return true;
                  }).toList(growable: false);

                  if (pendingFiltered.length != _pendingMessages.length) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _pendingMessages
                          ..clear()
                          ..addAll(pendingFiltered);
                      });
                    });
                  }

                  final merged = _dedupeMessages(<Map<String, dynamic>>[
                    ...rows,
                    ...pendingFiltered,
                  ]);
                  merged.sort((a, b) {
                    final at = (a['timestamp'] ?? '').toString();
                    final bt = (b['timestamp'] ?? '').toString();
                    return at.compareTo(bt);
                  });

                  if (merged.isNotEmpty) {
                    _scrollToBottomSoon();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: merged.length,
                    itemBuilder: (context, index) {
                      final data = merged[index];
                      final rowSender = (data['sender'] ?? '').toString();
                      final rowMessage = (data['message'] ?? '').toString();
                      final rowTimestamp = (data['timestamp'] ?? '').toString();

                      DateTime? ts;
                      try {
                        if (rowTimestamp.isNotEmpty) ts = DateTime.parse(rowTimestamp);
                      } catch (_) {}

                      final isMe = rowSender.toLowerCase() == sender.toLowerCase();

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.all(5),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            color: isMe
                                  ? widget.dync.onPrimaryContainer
                                  : widget.dync.primaryContainer,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "  $rowMessage  ",
                                style: TextStyle(
                                    color: isMe
                                        ? widget.dync.primaryContainer
                                        : widget.dync.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                ts == null
                                    ? ''
                                    : timeago.format(ts, locale: 'en_short'),
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 8,
                                    color: isMe
                                        ? widget.dync.primaryContainer
                                        : widget.dync.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: widget.dync.onPrimaryContainer,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: widget.dync.inversePrimary,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      height: MediaQuery.of(context).size.width / 6.5,
                      child: TextField(
                        controller: messagefield,
                          cursorColor: widget.dync.primary,
                          style: TextStyle(color: widget.dync.primary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    decoration: BoxDecoration(
                        color: widget.dync.onPrimary,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: IconButton(
                      onPressed: _sending ? null : _handleSend,
                        icon: Icon(Icons.send),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
