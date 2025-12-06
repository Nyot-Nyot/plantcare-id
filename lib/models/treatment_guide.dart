/// Treatment Guide Models for PlantCare.ID
///
/// Models for step-by-step treatment guides fetched from backend.
/// Includes GuideStep and TreatmentGuide with full serialization support.
library;

import 'package:collection/collection.dart';

/// Represents a single step in a treatment guide
class GuideStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> materials;
  final bool isCritical;
  final String? estimatedTime;

  const GuideStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.materials,
    required this.isCritical,
    this.estimatedTime,
  });

  /// Create GuideStep from JSON
  /// Throws [FormatException] if required fields are missing or invalid
  factory GuideStep.fromJson(Map<String, dynamic> json) {
    // Validate and parse step_number - required field, must be positive integer
    final stepNumberJson = json['step_number'];
    if (stepNumberJson == null) {
      throw FormatException('Missing required field: step_number');
    }
    final stepNumber = (stepNumberJson as num?)?.toInt();
    if (stepNumber == null || stepNumber <= 0) {
      throw FormatException(
        'Invalid step_number: $stepNumberJson (must be a positive integer)',
      );
    }

    // Validate required string fields
    final title = json['title']?.toString();
    if (title == null || title.isEmpty) {
      throw FormatException('Missing or empty required field: title');
    }

    final description = json['description']?.toString();
    if (description == null || description.isEmpty) {
      throw FormatException('Missing or empty required field: description');
    }

    // Parse materials list, handling both List and single string cases
    List<String> materialsList = [];
    final materialsJson = json['materials'];
    if (materialsJson is List) {
      materialsList = materialsJson.map((e) => e.toString()).toList();
    } else if (materialsJson is String) {
      materialsList = [materialsJson];
    }

    return GuideStep(
      stepNumber: stepNumber,
      title: title,
      description: description,
      imageUrl: json['image_url']?.toString(),
      materials: materialsList,
      isCritical: json['is_critical'] == true,
      estimatedTime: json['estimated_time']?.toString(),
    );
  }

  /// Convert GuideStep to JSON
  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'materials': materials,
      'is_critical': isCritical,
      'estimated_time': estimatedTime,
    };
  }

  /// Create a copy with optional new values
  GuideStep copyWith({
    int? stepNumber,
    String? title,
    String? description,
    String? imageUrl,
    List<String>? materials,
    bool? isCritical,
    String? estimatedTime,
  }) {
    return GuideStep(
      stepNumber: stepNumber ?? this.stepNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      materials: materials ?? this.materials,
      isCritical: isCritical ?? this.isCritical,
      estimatedTime: estimatedTime ?? this.estimatedTime,
    );
  }

  @override
  String toString() {
    return 'GuideStep(stepNumber: $stepNumber, title: $title, isCritical: $isCritical)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuideStep &&
        other.stepNumber == stepNumber &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        const ListEquality().equals(other.materials, materials) &&
        other.isCritical == isCritical &&
        other.estimatedTime == estimatedTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      stepNumber,
      title,
      description,
      imageUrl,
      const ListEquality().hash(materials),
      isCritical,
      estimatedTime,
    );
  }
}

/// Represents a complete treatment guide with multiple steps
class TreatmentGuide {
  final String id;
  final String plantId;
  final String diseaseName;
  final String severity;
  final String guideType;
  final List<GuideStep> steps;
  final List<String> materials;
  final String? estimatedDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TreatmentGuide({
    required this.id,
    required this.plantId,
    required this.diseaseName,
    required this.severity,
    required this.guideType,
    required this.steps,
    required this.materials,
    this.estimatedDuration,
    this.createdAt,
    this.updatedAt,
  });

  /// Create TreatmentGuide from JSON
  /// Throws [FormatException] if required fields are missing or invalid
  factory TreatmentGuide.fromJson(Map<String, dynamic> json) {
    // Validate required string fields
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('Missing or empty required field: id');
    }

    final plantId = json['plant_id']?.toString();
    if (plantId == null || plantId.isEmpty) {
      throw FormatException('Missing or empty required field: plant_id');
    }

    final diseaseName = json['disease_name']?.toString();
    if (diseaseName == null || diseaseName.isEmpty) {
      throw FormatException('Missing or empty required field: disease_name');
    }

    // Parse steps list - required, must not be empty
    List<GuideStep> stepsList = [];
    final stepsJson = json['steps'];
    if (stepsJson is List) {
      try {
        stepsList = stepsJson
            .map(
              (stepJson) => GuideStep.fromJson(
                stepJson is Map<String, dynamic> ? stepJson : {},
              ),
            )
            .toList();
      } on FormatException catch (e) {
        throw FormatException('Invalid step data: ${e.message}');
      }
    }
    if (stepsList.isEmpty) {
      throw FormatException('TreatmentGuide must have at least one step');
    }

    // Parse materials list
    List<String> materialsList = [];
    final materialsJson = json['materials'];
    if (materialsJson is List) {
      materialsList = materialsJson.map((e) => e.toString()).toList();
    }

    // Parse timestamps
    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    DateTime? updatedAt;
    if (json['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }

    return TreatmentGuide(
      id: id,
      plantId: plantId,
      diseaseName: diseaseName,
      severity: json['severity']?.toString() ?? 'unknown',
      guideType: json['guide_type']?.toString() ?? 'disease_treatment',
      steps: stepsList,
      materials: materialsList,
      estimatedDuration: json['estimated_duration']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert TreatmentGuide to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plant_id': plantId,
      'disease_name': diseaseName,
      'severity': severity,
      'guide_type': guideType,
      'steps': steps.map((step) => step.toJson()).toList(),
      'materials': materials,
      'estimated_duration': estimatedDuration,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with optional new values
  TreatmentGuide copyWith({
    String? id,
    String? plantId,
    String? diseaseName,
    String? severity,
    String? guideType,
    List<GuideStep>? steps,
    List<String>? materials,
    String? estimatedDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TreatmentGuide(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      diseaseName: diseaseName ?? this.diseaseName,
      severity: severity ?? this.severity,
      guideType: guideType ?? this.guideType,
      steps: steps ?? this.steps,
      materials: materials ?? this.materials,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validation: Check if guide has required fields
  bool isValid() {
    return id.isNotEmpty &&
        plantId.isNotEmpty &&
        diseaseName.isNotEmpty &&
        steps.isNotEmpty;
  }

  /// Validation: Check if all steps are valid
  bool hasValidSteps() {
    if (steps.isEmpty) return false;

    // Check if step numbers are sequential starting from 1
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].stepNumber != i + 1) return false;
      if (steps[i].title.isEmpty || steps[i].description.isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Get total number of steps
  int get totalSteps => steps.length;

  /// Get all critical steps
  List<GuideStep> get criticalSteps =>
      steps.where((step) => step.isCritical).toList();

  /// Get severity level as enum-like value
  String get severityLevel {
    final lowerSeverity = severity.toLowerCase();
    if (lowerSeverity.contains('low') || lowerSeverity.contains('ringan')) {
      return 'low';
    } else if (lowerSeverity.contains('high') ||
        lowerSeverity.contains('berat') ||
        lowerSeverity.contains('parah')) {
      return 'high';
    }
    return 'medium';
  }

  @override
  String toString() {
    return 'TreatmentGuide(id: $id, diseaseName: $diseaseName, steps: ${steps.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreatmentGuide &&
        other.id == id &&
        other.plantId == plantId &&
        other.diseaseName == diseaseName &&
        other.severity == severity &&
        other.guideType == guideType &&
        const ListEquality().equals(other.steps, steps) &&
        const ListEquality().equals(other.materials, materials) &&
        other.estimatedDuration == estimatedDuration &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      plantId,
      diseaseName,
      severity,
      guideType,
      const ListEquality().hash(steps),
      const ListEquality().hash(materials),
      estimatedDuration,
      createdAt,
      updatedAt,
    );
  }
}
