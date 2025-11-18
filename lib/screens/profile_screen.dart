import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'account_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _reminder = true;
  bool _tips = true;
  String? _appVersion;

  Future<void> _handleSignOut() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
    } catch (_) {}
    if (!mounted) return;
    ref.read(guestModeProvider.notifier).state = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  void initState() {
    super.initState();
    // Load app version once so it stays in sync with pubspec.yaml.
    PackageInfo.fromPlatform()
        .then((info) {
          if (!mounted) return;
          setState(() => _appVersion = '${info.appName} v${info.version}');
        })
        .catchError((_) {
          // ignore - we'll fall back to a sensible default in the UI
        });
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _listRow({
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) const SizedBox(height: 4),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(authUserProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: asyncUser.when(
          data: (user) {
            final displayName = () {
              if (user != null) {
                final metadata = user.userMetadata ?? {};
                final username = (metadata['username'] as String?)?.trim();
                if (username != null && username.isNotEmpty) return username;
                if (user.email != null && user.email!.isNotEmpty) {
                  return user.email!;
                }
              }
              return 'Tamu';
            }();

            final subtitle = ref.watch(guestModeProvider)
                ? 'Mode Tamu'
                : 'Terhubung';

            return Column(
              children: [
                // Header with gradient and avatar
                Container(
                  width: double.infinity,
                  height: 160,
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFE8F8F5), Colors.white],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.06 * 255).round(),
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionCard(
                          title: 'Akun',
                          children: [
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Akun',
                              subtitle: displayName,
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AccountSettingsScreen(
                                      email: displayName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Notifikasi',
                          children: [
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Pengingat Siram',
                              subtitle: 'Ingatkan kapan harus siram',
                              trailing: Switch(
                                value: _reminder,
                                activeThumbColor: AppColors.primary,
                                onChanged: (v) => setState(() => _reminder = v),
                              ),
                            ),
                            const Divider(
                              color: AppColors.surfaceBorder,
                              height: 1,
                            ),
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_objects_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Tips Perawatan',
                              subtitle: 'Tips mingguan',
                              trailing: Switch(
                                value: _tips,
                                activeThumbColor: AppColors.primary,
                                onChanged: (v) => setState(() => _tips = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Preferensi',
                          children: [
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.language,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Bahasa',
                              subtitle: 'Indonesia',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {},
                            ),
                            const Divider(
                              color: AppColors.surfaceBorder,
                              height: 1,
                            ),
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.format_paint_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Tema',
                              subtitle: 'Mode Terang',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: 'Bantuan',
                          children: [
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.help_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Tutorial',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {},
                            ),
                            const Divider(
                              color: AppColors.surfaceBorder,
                              height: 1,
                            ),
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.feedback_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Kirim Masukan',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {},
                            ),
                            const Divider(
                              color: AppColors.surfaceBorder,
                              height: 1,
                            ),
                            _listRow(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.imageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: 'Tentang Aplikasi',
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.muted,
                              ),
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Logout large outlined button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleSignOut,
                            icon: const Icon(
                              Icons.logout_outlined,
                              color: AppColors.danger,
                            ),
                            label: const Text(
                              'Keluar',
                              style: TextStyle(color: AppColors.danger),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.danger,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            _appVersion ?? 'Tanam.in',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Dibuat dengan 💚 untuk pecinta tanaman',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Terjadi kesalahan')),
        ),
      ),
    );
  }
}
