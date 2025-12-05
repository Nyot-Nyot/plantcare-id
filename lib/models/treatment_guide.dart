import 'package:freezed_annotation/freezed_annotation.dart';

part 'treatment_guide.freezed.dart';
part 'treatment_guide.g.dart';

@freezed
class TreatmentGuide with _$TreatmentGuide {
  factory TreatmentGuide({
    required String plantId,
    required String title,
    required List<GuideStep> steps,
    required Map<String, String> schedule,
    @Default(0) int totalSteps,
    @Default(0) int estimatedTotalTime,
  }) = _TreatmentGuide;

  factory TreatmentGuide.fromJson(Map<String, dynamic> json) =>
      _$TreatmentGuideFromJson(json);
}

@freezed
class GuideStep with _$GuideStep {
  factory GuideStep({
    required int step,
    required String title,
    required String description,
    @Default(0) int durationMinutes,
    @Default([]) List<String> materials,
    String? imageUrl,
    @Default('') String tips,
    @Default(false) bool isCompleted,
  }) = _GuideStep;

  factory GuideStep.fromJson(Map<String, dynamic> json) =>
      _$GuideStepFromJson(json);
}

@freezed
class DiseaseGuide with _$DiseaseGuide {
  factory DiseaseGuide({
    required String diseaseName,
    required String title,
    required String description,
    required List<GuideStep> steps,
    required List<String> preventiveMeasures,
    required List<String> recommendedTreatments,
  }) = _DiseaseGuide;

  factory DiseaseGuide.fromJson(Map<String, dynamic> json) =>
      _$DiseaseGuideFromJson(json);
}

@freezed
class GuideProgress with _$GuideProgress {
  factory GuideProgress({
    required String guideId,
    required String userId,
    @Default(1) int currentStep,
    @Default([]) List<int> completedSteps,
    @Default(false) bool isCompleted,
    DateTime? lastUpdated,
  }) = _GuideProgress;

  factory GuideProgress.fromJson(Map<String, dynamic> json) =>
      _$GuideProgressFromJson(json);
}