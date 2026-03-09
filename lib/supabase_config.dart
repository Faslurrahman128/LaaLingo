import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://dfuzirmctpvthqgzyext.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_L56K5qNNEB4JkmHDJdFUNQ_4xdZPgfS';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
