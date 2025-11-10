import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

/// Provides the current authenticated user as a Stream of User (or null).
/// If Supabase is not initialized, the stream will emit `null`.
final authUserProvider = StreamProvider<User?>((ref) {
  try {
    final client = Supabase.instance.client;
    // Map auth state changes to User?
    return client.auth.onAuthStateChange.map((event) => event.session?.user);
  } catch (_) {
    // Supabase not initialized yet; return a single null value stream.
    return Stream<User?>.value(null);
  }
});

/// Simple helper repository for auth actions.
class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
