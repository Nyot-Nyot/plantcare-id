import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  // intentionally not using the service variable here — keep simple permission check
  // Cek status permission (hanya contoh sederhana)
  try {
    // Dalam implementasi nyata, kita bisa cek status permission
    // Untuk sekarang, kita asumsikan granted jika service sudah diinisialisasi
    return true;
  } catch (e) {
    return false;
  }
});

class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  final NotificationService _service;

  NotificationSettingsNotifier(this._service) : super({
    'watering_reminder': true,
    'fertilizing_reminder': true,
    'general_tips': true,
  });

  Future<void> toggleSetting(String key) async {
    state = {
      ...state,
      key: !state[key]!,
    };
  }

  Future<void> schedulePlantCareReminder({
    required String plantName,
    required String careType,
    required DateTime scheduledTime,
  }) async {
    if (state['${careType}_reminder'] ?? true) {
      await _service.schedulePlantCareNotification(
        plantName: plantName,
        careType: careType,
        scheduledTime: scheduledTime,
      );
    }
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, Map<String, bool>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationSettingsNotifier(service);
});