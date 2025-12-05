import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/identify_result.dart';
import '../models/treatment_guide.dart';
import '../providers/guide_provider.dart';
import '../theme/colors.dart';
import '../widgets/guide_step_card.dart';
// import '../widgets/progress_bar_widget.dart';

class TreatmentGuideScreen extends ConsumerStatefulWidget {
  final String plantId;
  final String plantName;
  final bool fromResult;
  final IdentifyResult? result;

  const TreatmentGuideScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.fromResult = false,
    this.result,
  });

  @override
  ConsumerState<TreatmentGuideScreen> createState() =>
      _TreatmentGuideScreenState();
}

class _TreatmentGuideScreenState extends ConsumerState<TreatmentGuideScreen> {
  late Future<TreatmentGuide> _guideFuture;
  String? _userId; // TODO: Integrate with actual user auth

  @override
  void initState() {
    super.initState();
    // Set user ID (for now use placeholder, will be replaced with actual auth)
    _userId = 'local_user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Determine which provider to use based on available data
    if (widget.fromResult && widget.result != null) {
      _guideFuture = ref.read(resultGuideProvider(widget.result!).future);
    } else {
      _guideFuture = ref.read(plantGuideProvider(widget.plantId).future);
    }
  }

  Future<void> _toggleStepCompletion({
    required String guideId,
    required int stepNumber,
    required bool isCompleted,
  }) async {
    try {
      final progressNotifier = ref.read(guideProgressProvider.notifier);
      
      if (isCompleted) {
        await progressNotifier.markStepCompleted(
          guideId: guideId,
          stepNumber: stepNumber,
          userId: _userId!,
        );
      } else {
        await progressNotifier.markStepUncompleted(
          guideId: guideId,
          stepNumber: stepNumber,
          userId: _userId!,
        );
      }
      
      if (!mounted) return;

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted 
              ? 'Step $stepNumber ditandai selesai'
              : 'Step $stepNumber dibatalkan',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui progress: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _markAllStepsComplete({
    required String guideId,
    required int totalSteps,
  }) async {
    try {
      final progressNotifier = ref.read(guideProgressProvider.notifier);
      await progressNotifier.markGuideCompleted(
        guideId: guideId,
        userId: _userId!,
        totalSteps: totalSteps,
      );
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua step telah diselesaikan! 🎉'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menandai semua step: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildScheduleCard(Map<String, String> schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Jadwal Perawatan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...schedule.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEstimatedTimeCard(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeString = hours > 0 
      ? '$hours jam ${minutes > 0 ? '$minutes menit' : ''}'
      : '$minutes menit';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSuccess.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perkiraan Waktu',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total waktu yang dibutuhkan: $timeString',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(guideProgressProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Panduan Perawatan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<TreatmentGuide>(
        future: _guideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat panduan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      if (widget.fromResult && widget.result != null) {
                        _guideFuture = ref.read(resultGuideProvider(widget.result!).future);
                      } else {
                        _guideFuture = ref.read(plantGuideProvider(widget.plantId).future);
                      }
                    }),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Panduan tidak tersedia',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada panduan perawatan untuk tanaman ini',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final guide = snapshot.data!;
          final guideId = guide.plantId;
          final completedSteps = progressState[guideId] ?? [];
          final progressPercentage = completedSteps.isNotEmpty
              ? completedSteps.length / guide.totalSteps
              : 0.0;

          return SafeArea(
            child: Column(
              children: [
                // Header with progress
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.bg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progressPercentage,
                              minHeight: 8,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progressPercentage * 100).round()}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Estimated time card
                        _buildEstimatedTimeCard(guide.estimatedTotalTime),
                        const SizedBox(height: 16),
                        // Schedule card
                        if (guide.schedule.isNotEmpty) ...[
                          _buildScheduleCard(guide.schedule),
                          const SizedBox(height: 24),
                        ],

                        // Steps list
                        Column(
                          children: guide.steps.map((step) {
                            final isStepCompleted = completedSteps.contains(step.step);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GuideStepCard(
                                step: step,
                                isCompleted: isStepCompleted,
                                onCompletionChanged: (isCompleted) => _toggleStepCompletion(
                                  guideId: guideId,
                                  stepNumber: step.step,
                                  isCompleted: isCompleted,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        // Mark all complete button
                        ElevatedButton(
                          onPressed: () {
                            // Mark all steps as complete
                            _markAllStepsComplete(
                              guideId: guideId,
                              totalSteps: guide.totalSteps,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tandai Semua Selesai'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}