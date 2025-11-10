import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal Supabase initialization helper.
/// Call `SupabaseClientService.initFromEnv()` from `main()` after loading env vars.
class SupabaseClientService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with provided url and anonKey.
  static Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
