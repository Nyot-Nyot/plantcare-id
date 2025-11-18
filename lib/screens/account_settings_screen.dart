import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  final String? email;
  const AccountSettingsScreen({super.key, this.email});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    // Listen once to authUserProvider and prefill username when it becomes
    // available. Using ref.listen avoids doing side-effects inside build().
    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      next.whenData((u) {
        final m = u?.userMetadata ?? {};
        final name = m['username'] as String?;
        if (name != null && _usernameController.text.isEmpty) {
          _usernameController.text = name;
        }
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(authRepositoryProvider);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak ada perubahan')));
      return;
    }
    setState(() => _loading = true);
    try {
      await repo.updateProfile(
        username: username.isEmpty ? null : username,
        password: password.isEmpty ? null : password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perubahan tersimpan')));
      _passwordController.clear();
    } catch (e) {
      if (mounted) {
        var msg = 'Gagal menyimpan data.';
        try {
          final dyn = e as dynamic;
          final candidate =
              dyn.message ??
              dyn.error ??
              dyn.errorDescription ??
              dyn.description;
          if (candidate is String && candidate.isNotEmpty) msg = candidate;
        } catch (_) {
          // ignore and fall back to generic message
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $msg')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
    } catch (_) {}
    if (!mounted) return;
    ref.read(guestModeProvider.notifier).state = false;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  Widget build(BuildContext context) {
    // authUserProvider is listened in initState to prefill username; keep
    // build free from side-effects.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Akun',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Email',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.email ?? '-',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Username',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Username',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ubah Password',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Password baru',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Keluar',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
