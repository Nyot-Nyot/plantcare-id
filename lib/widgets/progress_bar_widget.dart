import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ProgressBarWidget extends StatelessWidget {
  final double progress;
  final double height;
  final Color backgroundColor;
  final Color progressColor;
  final bool showPercentage;

  const ProgressBarWidget({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor = AppColors.bg,
    this.progressColor = AppColors.primary,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedProgress,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
        
        // Percentage text
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$percentage% selesai',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}