import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuth {
  static final SupabaseClient client = Supabase.instance.client;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    return response;
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
