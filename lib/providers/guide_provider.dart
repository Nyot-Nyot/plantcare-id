import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../services/guide_service.dart';
import '../models/treatment_guide.dart';
import '../models/identify_result.dart';
import '../models/plant_collection.dart';

// Service Provider
final guideServiceProvider = Provider<GuideService>((ref) {
  return GuideService();
});

// Health Check Provider
final guideHealthProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(guideServiceProvider);
  return await service.checkHealth();
});

// Plant Guide Provider (by Plant ID)
final plantGuideProvider = FutureProvider.family<TreatmentGuide, String>((ref, plantId) async {
  final service = ref.watch(guideServiceProvider);
  return await service.getPlantGuide(plantId);
});

// Guide from IdentifyResult Provider
final resultGuideProvider = FutureProvider.family<TreatmentGuide, IdentifyResult>((ref, result) async {
  final service = ref.watch(guideServiceProvider);
  return await service.generateGuideFromResult(result);
});

// Guide from PlantCollection Provider
final collectionGuideProvider = FutureProvider.family<TreatmentGuide, PlantCollection>((ref, collection) async {
  final service = ref.watch(guideServiceProvider);
  return await service.getGuideForCollection(collection);
});

// Progress State Notifier
class GuideProgressNotifier extends StateNotifier<Map<String, List<int>>> {
  final GuideService _service;
  final Logger _logger = Logger();

  GuideProgressNotifier(this._service) : super({});

  /// Mark a step as completed for a guide
  Future<void> markStepCompleted({
    required String guideId,
    required int stepNumber,
    required String userId,
  }) async {
    try {
      final completedSteps = {...state[guideId] ?? []};
      completedSteps.add(stepNumber);
      
      // Update local state
      state = {
        ...state,
        guideId: completedSteps.toList()..sort(),
      };

      // Save to backend (async - don't await for UI responsiveness)
      Future.microtask(() async {
        try {
          await _service.saveGuideProgress(
            guideId: guideId,
            userId: userId,
            currentStep: stepNumber + 1,
            completedSteps: completedSteps.toList(),
            isCompleted: false,
          );
        } catch (e) {
          _logger.e('Failed to save progress to backend: $e');
        }
      });
    } catch (e) {
      _logger.e('Failed to mark step as completed: $e');
      rethrow;
    }
  }

  /// Mark a step as uncompleted
  Future<void> markStepUncompleted({
    required String guideId,
    required int stepNumber,
    required String userId,
  }) async {
    try {
      final completedSteps = {...state[guideId] ?? []};
      completedSteps.remove(stepNumber);
      
      state = {
        ...state,
        guideId: completedSteps.toList()..sort(),
      };

      // Save to backend
      Future.microtask(() async {
        try {
          await _service.saveGuideProgress(
            guideId: guideId,
            userId: userId,
            currentStep: stepNumber,
            completedSteps: completedSteps.toList(),
            isCompleted: false,
          );
        } catch (e) {
          _logger.e('Failed to save progress to backend: $e');
        }
      });
    } catch (e) {
      _logger.e('Failed to mark step as uncompleted: $e');
      rethrow;
    }
  }

  /// Mark guide as completed
  Future<void> markGuideCompleted({
    required String guideId,
    required String userId,
    required int totalSteps,
  }) async {
    try {
      final completedSteps = List.generate(totalSteps, (index) => index + 1);
      
      state = {
        ...state,
        guideId: completedSteps,
      };

      // Save to backend
      await _service.saveGuideProgress(
        guideId: guideId,
        userId: userId,
        currentStep: totalSteps,
        completedSteps: completedSteps,
        isCompleted: true,
      );
    } catch (e) {
      _logger.e('Failed to mark guide as completed: $e');
      rethrow;
    }
  }

  /// Get completed steps for a guide
  List<int> getCompletedSteps(String guideId) {
    return state[guideId] ?? [];
  }

  /// Check if a step is completed
  bool isStepCompleted(String guideId, int stepNumber) {
    return state[guideId]?.contains(stepNumber) ?? false;
  }

  /// Get progress percentage
  double getProgressPercentage(String guideId, int totalSteps) {
    if (totalSteps == 0) return 0.0;
    final completed = getCompletedSteps(guideId).length;
    return completed / totalSteps;
  }

  /// Clear progress for a guide
  void clearProgress(String guideId) {
    final newState = {...state};
    newState.remove(guideId);
    state = newState;
  }

  /// Reset all progress (for testing/logout)
  void resetAllProgress() {
    state = {};
  }
}

// Progress Provider
final guideProgressProvider = StateNotifierProvider<GuideProgressNotifier, Map<String, List<int>>>((ref) {
  final service = ref.watch(guideServiceProvider);
  return GuideProgressNotifier(service);
});

// Provider untuk mendapatkan progress untuk guide tertentu
final guideProgressForProvider = Provider.family<double, String>((ref, guideId) {
  final progressState = ref.watch(guideProgressProvider);
  final completedSteps = progressState[guideId]?.length ?? 0;
  
  // Default to 0 if we don't know total steps
  return completedSteps.toDouble();
});