import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_id/providers/auth_provider.dart' as local;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Small test subclass that exposes the protected _withRetry helper so we
/// can unit test retry behaviour without depending on the full Supabase
/// backend.
class TestAuthRepository extends local.AuthRepository {
  TestAuthRepository() : super(SupabaseClient('', ''));

  Future<T> callWithRetry<T>(
    Future<T> Function() fn, {
    int attempts = 2,
    Duration delay = const Duration(milliseconds: 1),
  }) {
    return super.callWithRetry(fn, attempts: attempts, delay: delay);
  }
}

void main() {
  group('AuthRepository._withRetry', () {
    test('returns value when function succeeds', () async {
      final repo = TestAuthRepository();
      final res = await repo.callWithRetry(() async => 'ok');
      expect(res, 'ok');
    });

    test('retries on SocketException then succeeds', () async {
      final repo = TestAuthRepository();
      int calls = 0;
      final res = await repo.callWithRetry(() async {
        calls += 1;
        if (calls == 1) throw const SocketException('network');
        return 'recovered';
      }, attempts: 2);
      expect(res, 'recovered');
      expect(calls, 2);
    });

    test(
      'throws AuthException with canRetry on repeated SocketException',
      () async {
        final repo = TestAuthRepository();
        Future<String> failing() async {
          throw const SocketException('still down');
        }

        try {
          await repo.callWithRetry(failing, attempts: 2);
          fail('Expected AuthException');
        } catch (e) {
          expect(e, isA<local.AuthException>());
          final a = e as local.AuthException;
          expect(a.canRetry, isTrue);
          expect(a.message, contains('Koneksi'));
        }
      },
    );
  });
}
