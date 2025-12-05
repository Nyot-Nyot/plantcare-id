import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal Supabase initialization helper.
/// Call `SupabaseClientService.initFromEnv()` from `main()` after loading env vars.
class SupabaseClientService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Singleton instance accessor
  static SupabaseClientService? _instance;
  
  SupabaseClientService._internal();
  
  factory SupabaseClientService.instance() {
    if (_instance == null) {
      throw Exception('SupabaseClientService not initialized. Call init() first.');
    }
    return _instance!;
  }
  
  /// Initialize Supabase with provided url and anonKey.
  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    if (_instance == null) {
      await Supabase.initialize(url: url, anonKey: anonKey);
      _instance = SupabaseClientService._internal();
      debugPrint('✅ SupabaseClientService initialized');
    } else {
      debugPrint('⚠️ SupabaseClientService already initialized');
    }
  }
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _instance != null;
}