/// Treatment Guide Models for PlantCare.ID
///
/// Models for step-by-step treatment guides fetched from backend.
/// Includes GuideStep and TreatmentGuide with full serialization support.
library;

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
  factory GuideStep.fromJson(Map<String, dynamic> json) {
    // Parse materials list, handling both List and single string cases
    List<String> materialsList = [];
    final materialsJson = json['materials'];
    if (materialsJson is List) {
      materialsList = materialsJson.map((e) => e.toString()).toList();
    } else if (materialsJson is String) {
      materialsList = [materialsJson];
    }

    return GuideStep(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
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
  factory TreatmentGuide.fromJson(Map<String, dynamic> json) {
    // Parse steps list
    List<GuideStep> stepsList = [];
    final stepsJson = json['steps'];
    if (stepsJson is List) {
      stepsList = stepsJson
          .map(
            (stepJson) => GuideStep.fromJson(
              stepJson is Map<String, dynamic> ? stepJson : {},
            ),
          )
          .toList();
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
      id: json['id']?.toString() ?? '',
      plantId: json['plant_id']?.toString() ?? '',
      diseaseName: json['disease_name']?.toString() ?? '',
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
        other.severity == severity;
  }

  @override
  int get hashCode {
    return Object.hash(id, plantId, diseaseName, severity);
  }
}
