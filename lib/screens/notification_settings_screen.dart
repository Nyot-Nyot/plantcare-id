import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi'),
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jenis Notifikasi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atur notifikasi apa saja yang ingin Anda terima',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),

              // Setting Items
              _buildSettingSwitch(
                context: context,
                title: 'Pengingat Penyiraman',
                subtitle: 'Notifikasi untuk jadwal penyiraman tanaman',
                value: notificationSettings['watering_reminder'] ?? true,
                onChanged: (value) => notifier.toggleSetting('watering_reminder'),
              ),
              _buildSettingSwitch(
                context: context,
                title: 'Pengingat Pemupukan',
                subtitle: 'Notifikasi untuk jadwal pemberian pupuk',
                value: notificationSettings['fertilizing_reminder'] ?? true,
                onChanged: (value) => notifier.toggleSetting('fertilizing_reminder'),
              ),
              _buildSettingSwitch(
                context: context,
                title: 'Tips Perawatan',
                subtitle: 'Tips dan saran perawatan tanaman mingguan',
                value: notificationSettings['general_tips'] ?? true,
                onChanged: (value) => notifier.toggleSetting('general_tips'),
              ),

              const SizedBox(height: 30),

              // Test Notification Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement test notification
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi percobaan dikirim'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.surfaceBorder),
                  ),
                  child: const Text('Kirim Notifikasi Percobaan'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}