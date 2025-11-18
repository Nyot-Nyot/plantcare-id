import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/decorated_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegTokens {
  _RegTokens._();
  static const double heroHeight = 342;
  static const double horizontalPadding = 24;
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 32;
  static const double fieldRadius = 16;
  static const double buttonHeight = 48;
}

// DecoratedField extracted to shared widget at lib/widgets/decorated_field.dart

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmController.text) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      }
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signUp(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      final msg = e is AuthException
          ? e.message
          : (e is Exception ? e.toString() : 'Pendaftaran gagal');
      final canRetry = e is AuthException && e.canRetry;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            action: canRetry
                ? SnackBarAction(label: 'Coba lagi', onPressed: _submit)
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SizedBox(
            height: _RegTokens.heroHeight,
            width: double.infinity,
            child: Image.asset(
              'assets/Hero.webp',
              fit: BoxFit.cover,
              color: Colors.black.withAlpha((0.3 * 255).round()),
              colorBlendMode: BlendMode.dstATop,
            ),
          ),
          Container(
            height: _RegTokens.heroHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Colors.white],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 88),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.eco_outlined,
                        color: AppColors.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _RegTokens.spacingSmall),
                Text(
                  'Buat Akun',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: _RegTokens.spacingSmall),
                Text(
                  'Daftar untuk memulai perjalanan berkebunmu 🌱',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: _RegTokens.spacingLarge),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _RegTokens.horizontalPadding,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFECF0F1),
                        width: 1.2,
                      ),
                    ),
                    padding: EdgeInsets.all(_RegTokens.horizontalPadding),
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Email',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingSmall),
                              DecoratedField(
                                height: _RegTokens.buttonHeight,
                                radius: _RegTokens.fieldRadius,
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'nama@email.com',
                                    isCollapsed: true,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Email required'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingMedium),
                              Text(
                                'Kata Sandi',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingSmall),
                              DecoratedField(
                                height: _RegTokens.buttonHeight,
                                radius: _RegTokens.fieldRadius,
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '••••••••',
                                    isCollapsed: true,
                                  ),
                                  obscureText: true,
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Password min 6 chars'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingMedium),
                              Text(
                                'Konfirmasi Kata Sandi',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingSmall),
                              DecoratedField(
                                height: _RegTokens.buttonHeight,
                                radius: _RegTokens.fieldRadius,
                                child: TextFormField(
                                  controller: _confirmController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '••••••••',
                                    isCollapsed: true,
                                  ),
                                  obscureText: true,
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Confirm password'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingMedium),
                              SizedBox(
                                height: _RegTokens.buttonHeight,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _RegTokens.fieldRadius,
                                      ),
                                    ),
                                  ),
                                  child: _loading
                                      ? CircularProgressIndicator(
                                          color: AppColors.onPrimary,
                                        )
                                      : const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: _RegTokens.spacingSmall),
                              TextButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed('/auth'),
                                child: Text(
                                  'Sudah punya akun? Masuk',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _RegTokens.spacingLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
