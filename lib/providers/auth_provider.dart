import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local guest mode flag. When true the app treats the session as a local
/// guest and avoids creating any accounts on Supabase. This is the preferred
/// approach for demo/preview mode so we don't pollute the Supabase project
/// with transient accounts.
final guestModeProvider = StateProvider<bool>((ref) => false);

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
/// Represents an auth-level failure that should be shown to the user.
/// `canRetry` is true for transient/network errors where retry may help.
class AuthException implements Exception {
  final String message;
  final bool canRetry;
  AuthException(this.message, {this.canRetry = false});
  @override
  String toString() => message;
}

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  // Internal helper: run an async operation with a simple retry for
  // transient network errors.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int attempts = 2,
    Duration delay = const Duration(milliseconds: 400),
  }) async {
    int tries = 0;
    while (true) {
      tries += 1;
      try {
        return await fn();
      } on SocketException catch (_) {
        if (tries >= attempts) {
          throw AuthException(
            'Koneksi jaringan bermasalah. Silakan periksa koneksi dan coba lagi.',
            canRetry: true,
          );
        }
        await Future.delayed(delay);
        continue;
      } on TimeoutException catch (_) {
        if (tries >= attempts) {
          throw AuthException(
            'Permintaan memakan waktu terlalu lama. Coba lagi.',
            canRetry: true,
          );
        }
        await Future.delayed(delay);
        continue;
      } catch (e) {
        // Non-network error: convert to a user-friendly message and rethrow
        // as AuthException to simplify UI handling.
        final msg = e.toString();
        throw AuthException(msg, canRetry: false);
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    return _withRetry(() async {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) {
        throw AuthException('Gagal masuk. Pastikan email dan password benar.');
      }
    });
  }

  Future<void> signUp(String email, String password) async {
    return _withRetry(() async {
      final res = await _client.auth.signUp(email: email, password: password);
      if (res.user == null) {
        throw AuthException('Pendaftaran gagal. Coba lagi.');
      }
    });
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      // signOut failures are non-fatal for the app flow; surface as AuthException
      throw AuthException('Gagal keluar dari akun. Coba lagi.');
    }
  }

  /// Update profile information for the current user.
  ///
  /// `username` will be stored inside the user's metadata under the
  /// `username` key. `password` will update the user's password.
  Future<void> updateProfile({String? username, String? password}) async {
    // Build attributes using the Supabase UserAttributes helper if available.
    try {
      await _client.auth.updateUser(
        UserAttributes(
          password: password,
          data: username != null ? {'username': username} : null,
        ),
      );
    } on SocketException catch (_) {
      throw AuthException(
        'Koneksi jaringan bermasalah saat memperbarui profil.',
        canRetry: true,
      );
    } catch (e) {
      final msg = e.toString();
      throw AuthException(msg, canRetry: false);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
