import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/identify_result.dart';
import '../models/plant_collection.dart';
import 'collection_database.dart';

/// Repository layer for collection data access
/// Abstracts database operations and provides business logic
/// Follows repository pattern from architect.md
class CollectionRepository {
  final CollectionDatabase _db;

  CollectionRepository({CollectionDatabase? database})
    : _db = database ?? CollectionDatabase.instance;

  /// Save an identification result to collection
  /// Copies image to local storage and creates collection entry
  Future<PlantCollection> saveFromIdentification({
    required IdentifyResult result,
    required File imageFile,
    String? userId,
    String? customName,
    String? notes,
  }) async {
    // Copy image to permanent storage
    final savedImagePath = await _saveImage(imageFile);

    // Create collection entry
    final collection = PlantCollection(
      userId: userId,
      plantCatalogId: result.id,
      customName: customName ?? result.commonName ?? 'Tanaman Baru',
      scientificName: result.scientificName,
      imageUrl: savedImagePath,
      notes: notes,
      identificationData: PlantCollection.encodeIdentificationData({
        'id': result.id,
        'common_name': result.commonName,
        'scientific_name': result.scientificName,
        'confidence': result.confidence,
        'provider': result.provider,
        'care': result.care,
        'description': result.description,
        'health_assessment': result.healthAssessment,
      }),
      createdAt: DateTime.now(),
      confidence: result.confidence,
      synced: false,
    );

    final id = await _db.insert(collection);
    return collection.copyWith(id: id);
  }

  /// Copy image file to app's document directory
  Future<String> _saveImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final collectionDir = Directory('${directory.path}/collections');

    // Create collections directory if it doesn't exist
    if (!await collectionDir.exists()) {
      await collectionDir.create(recursive: true);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(imageFile.path);
    final newPath = '${collectionDir.path}/${timestamp}_collection$extension';

    // Copy file
    final savedFile = await imageFile.copy(newPath);
    return savedFile.path;
  }

  /// Get all collections for a user
  Future<List<PlantCollection>> getAllCollections({String? userId}) async {
    return await _db.getAll(userId: userId);
  }

  /// Get a single collection by ID
  Future<PlantCollection?> getCollectionById(int id) async {
    return await _db.getById(id);
  }

  /// Update collection
  Future<void> updateCollection(PlantCollection collection) async {
    await _db.update(collection);
  }

  /// Delete collection and its image
  Future<void> deleteCollection(int id) async {
    final collection = await _db.getById(id);
    if (collection != null) {
      // Delete image file
      final imageFile = File(collection.imageUrl);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Delete database entry
      await _db.delete(id);
    }
  }

  /// Update notes for a collection
  Future<void> updateNotes(int id, String notes) async {
    final collection = await _db.getById(id);
    if (collection != null) {
      await _db.update(collection.copyWith(notes: notes));
    }
  }

  /// Update custom name for a collection
  Future<void> updateCustomName(int id, String customName) async {
    final collection = await _db.getById(id);
    if (collection != null) {
      await _db.update(collection.copyWith(customName: customName));
    }
  }

  /// Update last cared at timestamp
  Future<void> updateLastCaredAt(int id) async {
    await _db.updateLastCaredAt(id, DateTime.now());
  }

  /// Search collections
  Future<List<PlantCollection>> searchCollections(
    String query, {
    String? userId,
  }) async {
    return await _db.search(query, userId: userId);
  }

  /// Get collection count
  Future<int> getCollectionCount({String? userId}) async {
    return await _db.getCount(userId: userId);
  }

  /// Get unsynced collections (for future backend sync)
  Future<List<PlantCollection>> getUnsyncedCollections({String? userId}) async {
    return await _db.getUnsynced(userId: userId);
  }

  /// Mark collection as synced
  Future<void> markAsSynced(int id) async {
    await _db.markAsSynced(id);
  }

  /// Sync collections with backend (stub for future implementation)
  /// This will be called when online to sync local changes to server
  Future<void> syncCollections({String? userId}) async {
    final unsynced = await getUnsyncedCollections(userId: userId);

    // TODO: Implement actual sync logic with backend API
    // For now, this is just a stub that logs the unsynced items
    // Future implementation should:
    // 1. POST new collections to backend
    // 2. PUT updated collections
    // 3. Handle conflicts (last-write-wins or merge strategies)
    // 4. Mark items as synced after successful upload

    // Stub implementation - just acknowledge unsynced items exist
    // In production: iterate and sync each collection
    // ignore: unused_local_variable
    final unsyncedCount = unsynced.length;
    // TODO: Implement actual backend sync API calls here
  }
}
