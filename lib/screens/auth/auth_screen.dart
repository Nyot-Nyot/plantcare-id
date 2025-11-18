import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/decorated_field.dart';

// Local sizing and spacing tokens for this screen — avoid magic numbers.
class _AuthTokens {
  _AuthTokens._();

  static const double heroHeight = 342;
  static const double iconBoxSize = 64;
  static const double iconSize = 32;
  static const double cardRadius = 24;
  static const double fieldRadius = 16;
  static const double horizontalPadding = 24;
  static const double spacingLarge = 32;
  static const double spacingMedium = 16;
  static const double spacingSmall = 8;
  static const double buttonHeight = 48;
  static const Color dividerColor = Color(0xFFE8F8F5);
}

// DecoratedField is now provided as a shared widget in lib/widgets/decorated_field.dart

/// Auth screen redesigned to mirror the Figma layout: top hero image with
/// gradient overlay, centered brand icon, title/subtitle, and a rounded
/// login card with styled inputs and primary/secondary actions.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signIn(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      final canRetry = e is AuthException && e.canRetry;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            action: canRetry
                ? SnackBarAction(label: 'Coba lagi', onPressed: _signIn)
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

  Future<void> _enterGuestMode() async {
    // Move guest-mode activation into its own method so we can keep the
    // mounted checks close to the async boundary and avoid using the
    // BuildContext across async gaps.
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
    } catch (_) {
      // ignore sign out errors for guest flow
    }
    if (!mounted) return;
    ref.read(guestModeProvider.notifier).state = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Local hero image with reduced opacity (bundled asset)
          SizedBox(
            height: _AuthTokens.heroHeight,
            width: double.infinity,
            child: Image.asset(
              'assets/Hero.webp',
              fit: BoxFit.cover,
              color: Colors.black.withAlpha((0.3 * 255).round()),
              colorBlendMode: BlendMode.dstATop,
            ),
          ),
          // Gradient overlay
          Container(
            height: _AuthTokens.heroHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Colors.white],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 88),
                // Centered brand icon
                Center(
                  child: Container(
                    width: _AuthTokens.iconBoxSize,
                    height: _AuthTokens.iconBoxSize,
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(
                        _AuthTokens.fieldRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.eco_outlined,
                        color: AppColors.onPrimary,
                        size: _AuthTokens.iconSize,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _AuthTokens.spacingSmall),
                Text(
                  'Tanam.in',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: _AuthTokens.spacingSmall),
                Text(
                  'Selamat datang kembali! 🌿',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: _AuthTokens.spacingLarge),

                // Card containing form
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _AuthTokens.horizontalPadding,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(
                        _AuthTokens.cardRadius,
                      ),
                      border: Border.all(
                        color: const Color(0xFFECF0F1),
                        width: 1.2,
                      ),
                    ),
                    padding: EdgeInsets.all(_AuthTokens.horizontalPadding),
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
                              const SizedBox(height: _AuthTokens.spacingSmall),
                              DecoratedField(
                                height: _AuthTokens.buttonHeight,
                                radius: _AuthTokens.fieldRadius,
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
                              const SizedBox(height: _AuthTokens.spacingMedium),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kata Sandi',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: Text(
                                      'Lupa?',
                                      style: TextStyle(color: green),
                                    ),
                                  ),
                                ],
                              ),
                              DecoratedField(
                                height: _AuthTokens.buttonHeight,
                                radius: _AuthTokens.fieldRadius,
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
                              const SizedBox(height: _AuthTokens.spacingMedium),
                              SizedBox(
                                height: _AuthTokens.buttonHeight,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _AuthTokens.fieldRadius,
                                      ),
                                    ),
                                  ),
                                  child: _loading
                                      ? CircularProgressIndicator(
                                          color: AppColors.onPrimary,
                                        )
                                      : const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: _AuthTokens.spacingSmall),
                              SizedBox(
                                height: _AuthTokens.buttonHeight,
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed('/auth/register'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _AuthTokens.fieldRadius,
                                      ),
                                    ),
                                    backgroundColor: AppColors.bg,
                                  ),
                                  child: Text(
                                    'Daftar Akun Baru',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Divider with 'atau' and guest mode row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: _AuthTokens.dividerColor,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'atau',
                                style: TextStyle(color: Color(0xFF95A5A6)),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: _AuthTokens.dividerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _enterGuestMode(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Lanjut Tanpa Akun (Mode Tamu)',
                              style: TextStyle(color: green, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
