import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/treatment_guide.dart';
import '../theme/colors.dart';

class GuideStepCard extends ConsumerStatefulWidget {
  final GuideStep step;
  final bool isCompleted;
  final ValueChanged<bool>? onCompletionChanged;
  final bool showCompletionToggle;

  const GuideStepCard({
    super.key,
    required this.step,
    this.isCompleted = false,
    this.onCompletionChanged,
    this.showCompletionToggle = true,
  });

  @override
  ConsumerState<GuideStepCard> createState() => _GuideStepCardState();
}

class _GuideStepCardState extends ConsumerState<GuideStepCard> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  void didUpdateWidget(GuideStepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      setState(() {
        _isCompleted = widget.isCompleted;
      });
    }
  }

  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    
    if (widget.onCompletionChanged != null) {
      widget.onCompletionChanged!(_isCompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCompleted ? AppColors.primary : AppColors.surfaceBorder,
          width: _isCompleted ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan nomor step dan checkbox
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isCompleted 
                  ? AppColors.primary.withValues(alpha: 25) 
                  : AppColors.primary.withValues(alpha: 13),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Step number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _isCompleted ? AppColors.primary : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.step.step.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Step title
                Expanded(
                  child: Text(
                    widget.step.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isCompleted ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Completion toggle
                if (widget.showCompletionToggle)
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: _isCompleted,
                      onChanged: (value) => _toggleCompletion(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  widget.step.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Duration (if available)
                if (widget.step.durationMinutes > 0)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.step.durationMinutes} menit',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                
                // Materials (if available)
                if (widget.step.materials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bahan yang dibutuhkan:',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.step.materials.map((material) {
                      return Chip(
                        label: Text(material),
                        backgroundColor: AppColors.bg,
                        labelStyle: textTheme.bodySmall,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
                
                // Tips (if available)
                if (widget.step.tips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 51),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.step.tips,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}