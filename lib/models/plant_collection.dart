import 'dart:convert';

/// Model representing a plant saved in user's collection
/// Follows architect.md data model for collections table
///
/// ## copyWith Limitation
/// The `copyWith` method in this class has a known limitation:
/// it cannot set nullable fields to null. This is due to the standard
/// Dart pattern `field ?? this.field` which treats null as "no change".
///
/// ### Example of the limitation:
/// ```dart
/// final plant = PlantCollection(notes: "Some notes", ...);
/// final updated = plant.copyWith(notes: null); // Will NOT clear notes!
/// // updated.notes is still "Some notes", not null
/// ```
///
/// ### Solutions provided:
/// 1. **Helper methods**: Use `clearNotes()`, `clearLastCaredAt()`, etc.
///    ```dart
///    final cleared = plant.clearNotes(); // notes is now null
///    ```
///
/// 2. **Direct constructor**: For multiple null fields, use the constructor
///    ```dart
///    final updated = PlantCollection(
///      id: plant.id,
///      customName: plant.customName,
///      // ... copy other fields
///      notes: null, // This works!
///    );
///    ```
///
/// ### Future migration path:
/// Consider migrating to `freezed` package for automatic code generation:
/// - Add dependencies: `freezed`, `freezed_annotation`, `build_runner`
/// - Use `@freezed` annotation
/// - Run `flutter pub run build_runner build`
/// - Get proper copyWith with nullable support automatically
///
/// For current Sprint 2 scope, the simple implementation with helper
/// methods is sufficient and avoids additional build complexity.
class PlantCollection {
  final int? id; // Local database ID (autoincrement)
  final String? userId; // For future backend sync (nullable for guest users)
  final String? plantCatalogId; // From identification result
  final String customName; // User's custom name for the plant
  final String? scientificName;
  final String imageUrl; // Local file path to saved image
  final String? notes; // User's personal notes
  final String? identificationData; // JSON string of full IdentifyResult
  final DateTime createdAt;
  final DateTime? lastCaredAt;
  final String? reminders; // JSON string for future reminder data
  final double? confidence; // Identification confidence score
  final bool synced; // Sync status with backend

  PlantCollection({
    this.id,
    this.userId,
    this.plantCatalogId,
    required this.customName,
    this.scientificName,
    required this.imageUrl,
    this.notes,
    this.identificationData,
    required this.createdAt,
    this.lastCaredAt,
    this.reminders,
    this.confidence,
    this.synced = false,
  });

  /// Convert PlantCollection to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'plant_catalog_id': plantCatalogId,
      'custom_name': customName,
      'scientific_name': scientificName,
      'image_url': imageUrl,
      'notes': notes,
      'identification_data': identificationData,
      'created_at': createdAt.toIso8601String(),
      'last_cared_at': lastCaredAt?.toIso8601String(),
      'reminders': reminders,
      'confidence': confidence,
      'synced': synced ? 1 : 0,
    };
  }

  /// Create PlantCollection from database Map
  factory PlantCollection.fromMap(Map<String, dynamic> map) {
    return PlantCollection(
      id: map['id'] as int?,
      userId: map['user_id'] as String?,
      plantCatalogId: map['plant_catalog_id'] as String?,
      customName: map['custom_name'] as String,
      scientificName: map['scientific_name'] as String?,
      imageUrl: map['image_url'] as String,
      notes: map['notes'] as String?,
      identificationData: map['identification_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastCaredAt: map['last_cared_at'] != null
          ? DateTime.parse(map['last_cared_at'] as String)
          : null,
      reminders: map['reminders'] as String?,
      confidence: map['confidence'] as double?,
      synced: (map['synced'] as int?) == 1,
    );
  }

  /// Create a copy with updated fields
  ///
  /// **IMPORTANT LIMITATION:**
  /// This copyWith implementation cannot set nullable fields to null.
  /// For example, calling `copyWith(notes: null)` will NOT clear the notes,
  /// it will keep the existing value due to the `notes ?? this.notes` logic.
  ///
  /// **Workaround for clearing nullable fields:**
  /// Use specific helper methods like:
  /// - `clearNotes()` to set notes to null
  /// - `clearLastCaredAt()` to set lastCaredAt to null
  /// - etc.
  ///
  /// **Future Enhancement:**
  /// Consider using code generation tools like `freezed` package which handles
  /// nullable fields correctly in copyWith methods. This would require:
  /// 1. Add freezed and freezed_annotation dependencies
  /// 2. Add build_runner as dev dependency
  /// 3. Refactor this class to use @freezed annotation
  ///
  /// For now, this simple implementation is sufficient for current use cases.
  PlantCollection copyWith({
    int? id,
    String? userId,
    String? plantCatalogId,
    String? customName,
    String? scientificName,
    String? imageUrl,
    String? notes,
    String? identificationData,
    DateTime? createdAt,
    DateTime? lastCaredAt,
    String? reminders,
    double? confidence,
    bool? synced,
  }) {
    return PlantCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantCatalogId: plantCatalogId ?? this.plantCatalogId,
      customName: customName ?? this.customName,
      scientificName: scientificName ?? this.scientificName,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      identificationData: identificationData ?? this.identificationData,
      createdAt: createdAt ?? this.createdAt,
      lastCaredAt: lastCaredAt ?? this.lastCaredAt,
      reminders: reminders ?? this.reminders,
      confidence: confidence ?? this.confidence,
      synced: synced ?? this.synced,
    );
  }

  /// Helper methods to explicitly clear nullable fields
  /// These methods work around the copyWith limitation for setting null values

  /// Clear the notes field (set to null)
  PlantCollection clearNotes() {
    return PlantCollection(
      id: id,
      userId: userId,
      plantCatalogId: plantCatalogId,
      customName: customName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      notes: null, // Explicitly set to null
      identificationData: identificationData,
      createdAt: createdAt,
      lastCaredAt: lastCaredAt,
      reminders: reminders,
      confidence: confidence,
      synced: synced,
    );
  }

  /// Clear the lastCaredAt field (set to null)
  PlantCollection clearLastCaredAt() {
    return PlantCollection(
      id: id,
      userId: userId,
      plantCatalogId: plantCatalogId,
      customName: customName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      notes: notes,
      identificationData: identificationData,
      createdAt: createdAt,
      lastCaredAt: null, // Explicitly set to null
      reminders: reminders,
      confidence: confidence,
      synced: synced,
    );
  }

  /// Clear the reminders field (set to null)
  PlantCollection clearReminders() {
    return PlantCollection(
      id: id,
      userId: userId,
      plantCatalogId: plantCatalogId,
      customName: customName,
      scientificName: scientificName,
      imageUrl: imageUrl,
      notes: notes,
      identificationData: identificationData,
      createdAt: createdAt,
      lastCaredAt: lastCaredAt,
      reminders: null, // Explicitly set to null
      confidence: confidence,
      synced: synced,
    );
  }

  /// Helper to encode identification data to JSON string
  static String? encodeIdentificationData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return jsonEncode(data);
  }

  /// Helper to decode identification data from JSON string
  static Map<String, dynamic>? decodeIdentificationData(String? jsonString) {
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if the plant is healthy based on identification data
  ///
  /// Returns `true` if:
  /// - No identification data (benefit of doubt)
  /// - health_assessment is null (no disease check performed)
  /// - health_assessment.is_healthy is true
  ///
  /// Returns `false` if:
  /// - health_assessment.is_healthy is explicitly false
  ///
  /// This logic is centralized in the model for:
  /// - Single source of truth
  /// - Easy testing
  /// - Reusability across UI components
  /// - Separation of concerns
  bool get isHealthy {
    if (identificationData == null) return true;

    try {
      final data = decodeIdentificationData(identificationData);
      if (data == null) return true;

      final healthAssessment = data['health_assessment'];
      if (healthAssessment == null) return true;

      // Check is_healthy flag
      if (healthAssessment['is_healthy'] == false) {
        return false;
      }

      return true;
    } catch (e) {
      // Default to healthy if parsing fails
      return true;
    }
  }

  /// Get list of diseases from identification data
  ///
  /// Returns empty list if:
  /// - No identification data
  /// - health_assessment is null
  /// - diseases array is empty or invalid
  ///
  /// This provides convenient access to disease information
  /// without duplicating parsing logic.
  List<Map<String, dynamic>> get diseases {
    if (identificationData == null) return [];

    try {
      final data = decodeIdentificationData(identificationData);
      if (data == null) return [];

      final healthAssessment = data['health_assessment'];
      if (healthAssessment == null) return [];

      final diseasesRaw = healthAssessment['diseases'];
      if (diseasesRaw is! List) return [];

      return diseasesRaw.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the most likely disease (highest probability)
  ///
  /// Returns null if no diseases detected.
  /// Useful for showing summary information.
  Map<String, dynamic>? get primaryDisease {
    final diseaseList = diseases;
    if (diseaseList.isEmpty) return null;

    // Sort by probability and return highest
    diseaseList.sort((a, b) {
      final probA = (a['probability'] as num?)?.toDouble() ?? 0.0;
      final probB = (b['probability'] as num?)?.toDouble() ?? 0.0;
      return probB.compareTo(probA);
    });

    return diseaseList.first;
  }
}
