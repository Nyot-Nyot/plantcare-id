import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/collection_card.dart';
import '../widgets/dashboard_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(authUserProvider);
    final isGuest = ref.watch(guestModeProvider);

    // Derive the welcome text declaratively from the provider state so the
    // UI re-renders correctly when authentication state changes.
    final String welcome = asyncUser.when(
      data: (user) {
        if (user != null && user.email != null && user.email!.isNotEmpty) {
          return 'Halo, ${user.email}';
        }
        return isGuest ? 'Halo, Tamu! 🌿' : 'Halo, Tamu! 🌿';
      },
      loading: () => 'Halo, Tamu! 🌿',
      error: (_, __) => 'Halo, Tamu! 🌿',
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  welcome,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Siap bantu tanamanmu hari ini?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Top action tiles (two large tiles)
                Row(
                  children: [
                    Expanded(
                      child: DashboardTile(
                        icon: Icons.eco_outlined,
                        title: 'Kenali\nTanaman',
                        subtitle: 'Ambil foto tanaman',
                        background: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardTile(
                        icon: Icons.monitor_heart_outlined,
                        title: 'Cek Penyakit',
                        subtitle: 'Deteksi masalah',
                        background: AppColors.accent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                // Koleksi Terbaru header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Koleksi Terbaru',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Lihat Semua',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal list of collection cards
                SizedBox(
                  height: 274,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 2,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const CollectionCard(
                          title: 'Lidah Mertua',
                          status: 'Sehat',
                          lastCare: 'Terakhir dirawat: Baru saja',
                        );
                      }
                      return const CollectionCard(
                        title: 'Karet Kebo',
                        status: 'Sehat',
                        lastCare: 'Terakhir dirawat: Baru saja',
                        imageUrl: null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
