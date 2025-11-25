import 'dart:convert';

/// Model representing a plant saved in user's collection
/// Follows architect.md data model for collections table
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
}
