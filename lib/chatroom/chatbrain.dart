import 'package:supabase_flutter/supabase_flutter.dart';

class chatbrain {
  final client = Supabase.instance.client;
  late String sender;
  late String reciver;
  late String chatroom;

  chatbrain({required this.sender, required this.reciver}) {
    List<String> id = [
      sender.toLowerCase(),
      reciver.toLowerCase()
    ];
    id.sort();
    this.chatroom = id.join('_');
  }

  Future<void> sendmessage(Map<String, dynamic> data) async {
    final ts = (data['TimeStamp'] ?? DateTime.now().toIso8601String()).toString();
    await client.from('chat').insert({
      'chatroom': chatroom,
      'sender': data['Sender'],
      'reciver': data['Reciver'],
      'message': data['Message'],
      'timestamp': ts,
    });
  }

  Stream<List<Map<String, dynamic>>> recivemessage() {
    // Requires a primary key (commonly `id`) on `chat` table.
    return client
        .from('chat')
        .stream(primaryKey: ['id'])
        .eq('chatroom', chatroom)
        .order('timestamp');
  }
}
