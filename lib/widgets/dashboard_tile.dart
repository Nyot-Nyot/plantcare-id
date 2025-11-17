import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;

  const DashboardTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    // Use a consistent icon color across all dashboard tiles so the
    // visual rhythm is uniform regardless of the tile background.
    final iconColor = AppColors.onPrimary;
    // Fixed height to ensure tiles are uniform on the dashboard.
    return SizedBox(
      height: 178,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    // Keep the icon container background opacity consistent
                    // across all tiles so the icon block looks the same.
                    // Converted opacity to alpha to follow Flutter guidance
                    // (avoid .withOpacity deprecation).
                    color: Colors.white.withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(color: AppColors.onPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onPrimary.withAlpha((0.9 * 255).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
