import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/treatment_guide.dart';
import '../services/guide_service.dart';

/// Provider for GuideService singleton
final guideServiceProvider = Provider<GuideService>((ref) {
  return GuideService();
});

/// State notifier for managing current guide state
///
/// Handles the currently active guide being viewed by the user,
/// including step navigation and completion tracking.
class GuideNotifier extends StateNotifier<AsyncValue<TreatmentGuide?>> {
  final GuideService _service;

  GuideNotifier(this._service) : super(const AsyncValue.data(null));

  /// Load a guide by ID
  Future<void> loadGuideById(String id) async {
    state = const AsyncValue.loading();
    try {
      final guide = await _service.getGuideById(id);
      state = AsyncValue.data(guide);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load guides by plant ID (loads the first one if available)
  Future<void> loadGuideByPlantId(String plantId) async {
    state = const AsyncValue.loading();
    try {
      final guides = await _service.getGuidesByPlantId(plantId, limit: 1);
      state = AsyncValue.data(guides.isNotEmpty ? guides.first : null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear the current guide
  void clearGuide() {
    state = const AsyncValue.data(null);
  }

  /// Refresh the current guide
  Future<void> refreshGuide() async {
    final currentGuide = state.value;
    if (currentGuide != null) {
      await loadGuideById(currentGuide.id);
    }
  }
}

/// Provider for current guide state
final guideProvider =
    StateNotifierProvider<GuideNotifier, AsyncValue<TreatmentGuide?>>((ref) {
      final service = ref.watch(guideServiceProvider);
      return GuideNotifier(service);
    });

/// State notifier for managing guide list state
///
/// Handles lists of guides (e.g., for a specific plant or disease)
class GuideListNotifier
    extends StateNotifier<AsyncValue<List<TreatmentGuide>>> {
  final GuideService _service;

  GuideListNotifier(this._service) : super(const AsyncValue.loading());

  /// Load guides by plant ID with pagination
  Future<void> loadGuidesByPlantId(
    String plantId, {
    int limit = 10,
    int offset = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final guides = await _service.getGuidesByPlantId(
        plantId,
        limit: limit,
        offset: offset,
      );
      state = AsyncValue.data(guides);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear the guide list
  void clearGuides() {
    state = const AsyncValue.data([]);
  }
}

/// Provider for guide list state (e.g., for a plant)
/// Use with .family to create separate instances per plant ID
final guideListProvider =
    StateNotifierProvider.family<
      GuideListNotifier,
      AsyncValue<List<TreatmentGuide>>,
      String
    >((ref, plantId) {
      final service = ref.watch(guideServiceProvider);
      final notifier = GuideListNotifier(service);
      // Auto-load guides for this plant ID
      notifier.loadGuidesByPlantId(plantId);
      return notifier;
    });

/// State notifier for managing completed steps
///
/// Tracks which steps have been marked as completed by the user.
/// This is separate from the guide state to allow independent management
/// of completion progress.
class CompletedStepsNotifier extends StateNotifier<Set<int>> {
  CompletedStepsNotifier() : super({});

  /// Mark a step as completed
  void markStepCompleted(int stepNumber) {
    state = {...state, stepNumber};
  }

  /// Mark a step as incomplete
  void markStepIncomplete(int stepNumber) {
    state = state.where((step) => step != stepNumber).toSet();
  }

  /// Toggle step completion status
  void toggleStep(int stepNumber) {
    if (state.contains(stepNumber)) {
      markStepIncomplete(stepNumber);
    } else {
      markStepCompleted(stepNumber);
    }
  }

  /// Check if a step is completed
  bool isStepCompleted(int stepNumber) {
    return state.contains(stepNumber);
  }

  /// Reset all completed steps
  void resetProgress() {
    state = {};
  }

  /// Get completion percentage (0.0 to 1.0)
  double getCompletionPercentage(int totalSteps) {
    if (totalSteps == 0) return 0.0;
    return state.length / totalSteps;
  }

  /// Check if all steps are completed
  bool isGuideCompleted(int totalSteps) {
    return state.length >= totalSteps && totalSteps > 0;
  }

  /// Set multiple steps as completed at once
  void setCompletedSteps(Set<int> steps) {
    state = {...steps};
  }
}

/// Provider for completed steps state
final completedStepsProvider =
    StateNotifierProvider<CompletedStepsNotifier, Set<int>>((ref) {
      return CompletedStepsNotifier();
    });

/// Derived provider: Get steps from current guide
final guideStepsProvider = Provider<List<GuideStep>>((ref) {
  final guideState = ref.watch(guideProvider);
  return guideState.when(
    data: (guide) => guide?.steps ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Derived provider: Get current step number based on completion
/// Returns the next incomplete step, or total steps if all completed
final currentStepNumberProvider = Provider<int>((ref) {
  final steps = ref.watch(guideStepsProvider);
  final completedSteps = ref.watch(completedStepsProvider);

  if (steps.isEmpty) return 0;

  // Find first incomplete step
  for (int i = 0; i < steps.length; i++) {
    if (!completedSteps.contains(steps[i].stepNumber)) {
      return steps[i].stepNumber;
    }
  }

  // All steps completed, return last step number
  return steps.length;
});

/// Derived provider: Get completion progress (0.0 to 1.0)
final guideProgressProvider = Provider<double>((ref) {
  final steps = ref.watch(guideStepsProvider);
  final completedSteps = ref.watch(completedStepsProvider);

  if (steps.isEmpty) return 0.0;

  final completedCount = steps
      .where((step) => completedSteps.contains(step.stepNumber))
      .length;

  return completedCount / steps.length;
});

/// Derived provider: Check if guide is completed
final isGuideCompletedProvider = Provider<bool>((ref) {
  final steps = ref.watch(guideStepsProvider);
  final completedSteps = ref.watch(completedStepsProvider);

  if (steps.isEmpty) return false;

  return steps.every((step) => completedSteps.contains(step.stepNumber));
});

/// Derived provider: Get all critical steps
final criticalStepsProvider = Provider<List<GuideStep>>((ref) {
  final steps = ref.watch(guideStepsProvider);
  return steps.where((step) => step.isCritical).toList();
});

/// Derived provider: Get remaining steps (not completed)
final remainingStepsProvider = Provider<List<GuideStep>>((ref) {
  final steps = ref.watch(guideStepsProvider);
  final completedSteps = ref.watch(completedStepsProvider);

  return steps
      .where((step) => !completedSteps.contains(step.stepNumber))
      .toList();
});
