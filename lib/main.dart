import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_tabbed_screen.dart';
import 'screens/splash_screen.dart';
import 'services/camera_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_client.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - skip if google-services.json not configured)
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint(
      '⚠️ Firebase initialization failed (this is OK for development): $e',
    );
    debugPrint(
      '   To enable Firebase: Add google-services.json to android/app/',
    );
  }

  // Prefetch camera list early to avoid platform-channel initialization
  // races that can cause the 'ProcessCameraProvider.getInstance' error
  // seen on some Android devices when availableCameras() is called later.
  await CameraService.init();

  // Try to load environment variables from .env. This file should
  // contain SUPABASE_URL and SUPABASE_ANON_KEY. If the file is missing
  // we catch the error and continue so the app can run in dev without
  // crashing. See docs/setup_supabase.md for instructions to create a
  // Supabase project and obtain keys.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
      'No .env file found in app assets. If you need Supabase integration, add a .env file at project root and include it under `flutter.assets` in pubspec.yaml, then rebuild.',
    );

    // Extra diagnostic: attempt to read the bundled asset (works only if .env was added to assets and app rebuilt)
    try {
      final content = await rootBundle.loadString('.env');
      final hasUrl = content.contains('SUPABASE_URL=');
      final hasKey = content.contains('SUPABASE_ANON_KEY=');
      debugPrint(
        '.env bundled: true, has SUPABASE_URL: $hasUrl, has SUPABASE_ANON_KEY: $hasKey',
      );
    } catch (e2) {
      debugPrint(
        '.env bundled: false or unreadable (not included in app assets): $e2',
      );
    }
  }

  String? supabaseUrl;
  String? supabaseAnonKey;

  // Accessing `dotenv.env` will throw if the package wasn't initialized
  // (for example if `dotenv.load` failed). Guard that to avoid crashing
  // the app at startup.
  try {
    supabaseUrl = dotenv.env['SUPABASE_URL'];
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  } catch (e) {
    debugPrint('dotenv not initialized or error while reading .env: $e');
  }

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await SupabaseClientService.init(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    // If keys are missing we'll continue without initializing Supabase to
    // avoid crashing the app. The docs/setup_supabase.md explains how to
    // create the .env file with the proper values.
    debugPrint(
      'SUPABASE_URL or SUPABASE_ANON_KEY not found in .env; Supabase not initialized.',
    );
  }

  // Initialize Notification Service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    debugPrint('Notification service initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize notification service: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue without notifications - don't crash the app
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantCare ID',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/auth': (ctx) => const AuthScreen(),
        '/auth/register': (ctx) => const RegisterScreen(),
        '/home': (ctx) => const MainTabbedScreen(),
      },
    );
  }
}
