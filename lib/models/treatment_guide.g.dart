// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_guide.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TreatmentGuideImpl _$$TreatmentGuideImplFromJson(Map<String, dynamic> json) =>
    _$TreatmentGuideImpl(
      plantId: json['plantId'] as String,
      title: json['title'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      schedule: Map<String, String>.from(json['schedule'] as Map),
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      estimatedTotalTime: (json['estimatedTotalTime'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TreatmentGuideImplToJson(
  _$TreatmentGuideImpl instance,
) => <String, dynamic>{
  'plantId': instance.plantId,
  'title': instance.title,
  'steps': instance.steps,
  'schedule': instance.schedule,
  'totalSteps': instance.totalSteps,
  'estimatedTotalTime': instance.estimatedTotalTime,
};

_$GuideStepImpl _$$GuideStepImplFromJson(Map<String, dynamic> json) =>
    _$GuideStepImpl(
      step: (json['step'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      materials:
          (json['materials'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      imageUrl: json['imageUrl'] as String?,
      tips: json['tips'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$GuideStepImplToJson(_$GuideStepImpl instance) =>
    <String, dynamic>{
      'step': instance.step,
      'title': instance.title,
      'description': instance.description,
      'durationMinutes': instance.durationMinutes,
      'materials': instance.materials,
      'imageUrl': instance.imageUrl,
      'tips': instance.tips,
      'isCompleted': instance.isCompleted,
    };

_$DiseaseGuideImpl _$$DiseaseGuideImplFromJson(Map<String, dynamic> json) =>
    _$DiseaseGuideImpl(
      diseaseName: json['diseaseName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => GuideStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      preventiveMeasures: (json['preventiveMeasures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recommendedTreatments: (json['recommendedTreatments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$DiseaseGuideImplToJson(_$DiseaseGuideImpl instance) =>
    <String, dynamic>{
      'diseaseName': instance.diseaseName,
      'title': instance.title,
      'description': instance.description,
      'steps': instance.steps,
      'preventiveMeasures': instance.preventiveMeasures,
      'recommendedTreatments': instance.recommendedTreatments,
    };

_$GuideProgressImpl _$$GuideProgressImplFromJson(Map<String, dynamic> json) =>
    _$GuideProgressImpl(
      guideId: json['guideId'] as String,
      userId: json['userId'] as String,
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 1,
      completedSteps:
          (json['completedSteps'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$GuideProgressImplToJson(_$GuideProgressImpl instance) =>
    <String, dynamic>{
      'guideId': instance.guideId,
      'userId': instance.userId,
      'currentStep': instance.currentStep,
      'completedSteps': instance.completedSteps,
      'isCompleted': instance.isCompleted,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
