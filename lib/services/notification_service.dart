import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _firebaseAvailable = false;

  /// Inisialisasi service notifikasi
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if Firebase is available
    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;
      debugPrint('✅ Firebase Messaging available');
    } catch (e) {
      debugPrint('⚠️ Firebase not available, FCM features disabled: $e');
      _firebaseAvailable = false;
    }

    // Inisialisasi timezone untuk scheduled notifications
    tz.initializeTimeZones();

    // Konfigurasi untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Konfigurasi untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Setup Firebase Messaging only if available
    if (_firebaseAvailable && _firebaseMessaging != null) {
      try {
        // Request permission untuk Firebase Messaging
        NotificationSettings settings = await _firebaseMessaging!
            .requestPermission(alert: true, badge: true, sound: true);

        debugPrint('Permission granted: ${settings.authorizationStatus}');

        // Setup handler untuk messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(
          _handleBackgroundMessageOpened,
        );
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

        // Dapatkan token FCM
        String? token = await _firebaseMessaging!.getToken();
        debugPrint('FCM Token: $token');
      } catch (e) {
        debugPrint('⚠️ Firebase Messaging setup failed: $e');
        _firebaseAvailable = false;
      }
    }

    _isInitialized = true;
  }

  /// Handle pesan ketika aplikasi di foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'PlantCare ID',
      body: message.notification?.body ?? 'Pesan baru',
      payload: message.data['type'] ?? 'general',
    );
  }

  /// Handle pesan ketika aplikasi di background
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.notification?.title}');
    // Karena static method, kita tidak bisa akses instance method langsung
    // Jadi kita buat instance baru untuk menampilkan notifikasi
    final notificationService = NotificationService();
    await notificationService._showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'PlantCare ID',
      body: message.notification?.body ?? 'Pesan baru',
      payload: message.data['type'] ?? 'general',
    );
  }

  /// Handle ketika notifikasi di-tap dan aplikasi terbuka dari background
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    debugPrint('Message opened from background: ${message.data}');
    // Navigasi ke halaman yang sesuai berdasarkan payload
    // TODO: Implement navigation based on payload
  }

  /// Tampilkan local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'plantcare_channel_id',
          'PlantCare Notifications',
          channelDescription: 'Notifikasi untuk perawatan tanaman',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Jadwalkan local notification untuk perawatan tanaman
  Future<void> schedulePlantCareNotification({
    required String plantName,
    required String careType, // watering, fertilizing, etc.
    required DateTime scheduledTime,
    int? id,
  }) async {
    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'plantcare_schedule_id',
          'PlantCare Schedule',
          channelDescription: 'Jadwal perawatan tanaman',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id ?? plantName.hashCode + careType.hashCode,
      'Waktunya Merawat $plantName',
      'Jangan lupa untuk ${_getCareDescription(careType)}',
      scheduledTZTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'plant_care_$careType',
    );
  }

  String _getCareDescription(String careType) {
    switch (careType) {
      case 'watering':
        return 'menyiram tanaman';
      case 'fertilizing':
        return 'memberi pupuk';
      case 'pruning':
        return 'memangkas tanaman';
      default:
        return 'merawat tanaman';
    }
  }

  /// Batalkan notifikasi yang dijadwalkan
  Future<void> cancelScheduledNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Batalkan semua notifikasi yang dijadwalkan
  Future<void> cancelAllScheduledNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Dapatkan FCM token
  Future<String?> getFCMToken() async {
    if (!_firebaseAvailable || _firebaseMessaging == null) {
      debugPrint(
        '⚠️ Firebase Messaging tidak tersedia, tidak dapat mendapatkan FCM token',
      );
      return null;
    }
    return await _firebaseMessaging!.getToken();
  }

  /// Subscribe ke topic untuk notifikasi broadcast
  Future<void> subscribeToTopic(String topic) async {
    if (!_firebaseAvailable || _firebaseMessaging == null) {
      debugPrint(
        '⚠️ Firebase Messaging tidak tersedia, tidak dapat subscribe ke topic: $topic',
      );
      return;
    }
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  /// Unsubscribe dari topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_firebaseAvailable || _firebaseMessaging == null) {
      debugPrint(
        '⚠️ Firebase Messaging tidak tersedia, tidak dapat unsubscribe dari topic: $topic',
      );
      return;
    }
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
  }
}
