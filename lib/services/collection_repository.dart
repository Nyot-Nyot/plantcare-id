import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/identify_result.dart';
import '../models/plant_collection.dart';
import 'collection_database.dart';
import 'supabase_client.dart';
import 'sync_service.dart';

/// Repository layer for collection data access
/// Abstracts database operations and provides business logic
/// Follows repository pattern from architect.md
class CollectionRepository {
  final CollectionDatabase _db;
  late SyncService? _syncService;

  CollectionRepository({CollectionDatabase? database})
    : _db = database ?? CollectionDatabase.instance {
    // Initialize sync service if Supabase is available
    _initSyncService();
  }

  void _initSyncService() {
    try {
      // Check if Supabase is initialized
      if (SupabaseClientService.isInitialized) {
        _syncService = SyncService();
        debugPrint('✅ Sync service initialized');
      } else {
        _syncService = null;
        debugPrint('⚠️ Sync service not available (Supabase not initialized)');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize sync service: $e');
      _syncService = null;
    }
  }

  bool get isSyncAvailable => _syncService != null;

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
      identificationData: PlantCollection.encodeIdentificationData(
        result.toJson(),
      ),
      createdAt: DateTime.now(),
      confidence: result.confidence,
      synced: false, // Mark as unsynced initially
    );

    final id = await _db.insert(collection);
    final savedCollection = collection.copyWith(id: id);

    // Try to sync to Supabase if available
    if (isSyncAvailable) {
      try {
        await _syncService!.syncCollection(savedCollection);
        await _db.markAsSynced(id);
      } catch (e) {
        debugPrint('⚠️ Failed to sync new collection: $e');
        // Don't throw, keep collection locally
      }
    }

    return savedCollection;
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

    // Try to sync to Supabase
    if (isSyncAvailable) {
      try {
        await _syncService!.syncCollection(collection);
        await _db.markAsSynced(collection.id!);
      } catch (e) {
        debugPrint('⚠️ Failed to sync updated collection: $e');
      }
    }
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

      // Try to delete from Supabase
      if (isSyncAvailable) {
        try {
          await _syncService!.deleteCollection(id);
        } catch (e) {
          debugPrint('⚠️ Failed to delete collection from Supabase: $e');
        }
      }

      // Delete database entry
      await _db.delete(id);
    }
  }

  /// Helper method to sync collection updates to Supabase
  /// Retrieves the updated collection and syncs it if sync service is available
  Future<void> _syncCollectionUpdate(int id, String operationName) async {
    if (!isSyncAvailable) return;

    try {
      final collection = await _db.getById(id);
      if (collection != null) {
        await _syncService!.syncCollection(collection);
        await _db.markAsSynced(id);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to sync $operationName: $e');
    }
  }

  /// Update notes for a collection
  Future<void> updateNotes(int id, String notes) async {
    await _db.updateNotes(id, notes);
    await _syncCollectionUpdate(id, 'notes update');
  }

  /// Update custom name for a collection
  Future<void> updateCustomName(int id, String customName) async {
    await _db.updateCustomName(id, customName);
    await _syncCollectionUpdate(id, 'name update');
  }

  /// Update last cared at timestamp
  Future<void> updateLastCaredAt(int id) async {
    await _db.updateLastCaredAt(id, DateTime.now());
    await _syncCollectionUpdate(id, 'last cared update');
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

  /// Sync collections with backend
  Future<void> syncCollections({String? userId}) async {
    final unsynced = await getUnsyncedCollections(userId: userId);

    if (!isSyncAvailable) {
      debugPrint('⚠️ Sync service not available');
      return;
    }

    if (unsynced.isEmpty) {
      debugPrint('📭 No unsynced collections to sync');
      return;
    }

    debugPrint('🔄 Syncing ${unsynced.length} collections to Supabase...');

    try {
      await _syncService!.syncCollections(unsynced);

      // Mark all as synced
      for (final collection in unsynced) {
        if (collection.id != null) {
          await markAsSynced(collection.id!);
        }
      }

      debugPrint('✅ Sync completed successfully');
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
      rethrow;
    }
  }

  /// Check sync connection
  Future<bool> checkSyncConnection() async {
    if (!isSyncAvailable) return false;

    try {
      return await _syncService!.checkConnection();
    } catch (e) {
      return false;
    }
  }

  /// Get sync status summary
  Future<Map<String, dynamic>> getSyncStatus({String? userId}) async {
    final total = await getCollectionCount(userId: userId);
    final unsynced = await getUnsyncedCollections(userId: userId);

    return {
      'total': total,
      'unsynced': unsynced.length,
      'synced': total - unsynced.length,
      'sync_available': isSyncAvailable,
    };
  }

  /// Clear all collections (for testing/development)
  Future<void> clearAllCollections() async {
    await _db.deleteAll();
  }
}
