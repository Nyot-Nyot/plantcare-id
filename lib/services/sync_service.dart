// import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/plant_collection.dart';
import 'supabase_client.dart';

class SyncService {
  final SupabaseClient _supabase;

  SyncService() : _supabase = SupabaseClientService.client;

  /// Check if sync service is available
  bool get isAvailable => SupabaseClientService.isInitialized;

  /// Sync single collection to Supabase
  Future<void> syncCollection(PlantCollection collection) async {
    try {
      if (collection.id == null) {
        throw Exception('Collection ID is null, cannot sync');
      }

      if (!isAvailable) {
        throw Exception('Sync service not available (Supabase not initialized)');
      }

      // Convert collection to Supabase format
      final supabaseData = _toSupabaseData(collection);

      // Check if collection already exists in Supabase
      final existing = await _supabase
          .from('plant_collections')
      .select('id')
      .eq('local_id', collection.id!)
          .maybeSingle();

      if (existing == null) {
        // Insert new collection
        await _supabase
            .from('plant_collections')
            .insert(supabaseData);
      } else {
        // Update existing collection
        await _supabase
            .from('plant_collections')
    .update(supabaseData)
    .eq('local_id', collection.id!);
      }

      debugPrint('✅ Successfully synced collection: ${collection.customName}');
    } catch (e) {
      debugPrint('❌ Failed to sync collection: $e');
      rethrow;
    }
  }

  /// Sync multiple collections in batch
  Future<void> syncCollections(List<PlantCollection> collections) async {
    if (collections.isEmpty) {
      debugPrint('📭 No collections to sync');
      return;
    }

    if (!isAvailable) {
      throw Exception('Sync service not available (Supabase not initialized)');
    }

  debugPrint('🔄 Syncing ${collections.length} collections...');

    int successCount = 0;
    int failureCount = 0;

    for (final collection in collections) {
      try {
        await syncCollection(collection);
        successCount++;
      } catch (e) {
        failureCount++;
  debugPrint('⚠️ Failed to sync collection ${collection.id}: $e');
        // Continue with next collection
      }
    }

  debugPrint('✅ Sync completed: $successCount successful, $failureCount failed');
  }

  /// Delete collection from Supabase
  Future<void> deleteCollection(int localId) async {
    try {
      if (!isAvailable) {
        throw Exception('Sync service not available (Supabase not initialized)');
      }

      await _supabase
          .from('plant_collections')
          .delete()
          .eq('local_id', localId);
      
  debugPrint('🗑️ Deleted collection $localId from Supabase');
    } catch (e) {
  debugPrint('❌ Failed to delete collection from Supabase: $e');
      rethrow;
    }
  }

  /// Fetch collections from Supabase for a user
  Future<List<Map<String, dynamic>>> fetchUserCollections(String userId) async {
    try {
      if (!isAvailable) {
        throw Exception('Sync service not available (Supabase not initialized)');
      }

      final response = await _supabase
          .from('plant_collections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
  debugPrint('❌ Failed to fetch collections from Supabase: $e');
      return [];
    }
  }

  /// Check sync status
  Future<bool> checkConnection() async {
    try {
      if (!isAvailable) {
        return false;
      }

      // Simple ping query
      await _supabase
          .from('plant_collections')
          .select('count')
          .limit(1)
          .maybeSingle();
      
      return true;
    } catch (e) {
  debugPrint('❌ Sync service connection failed: $e');
      return false;
    }
  }

  /// Convert PlantCollection to Supabase format
  Map<String, dynamic> _toSupabaseData(PlantCollection collection) {
    return {
      'local_id': collection.id,
      'user_id': collection.userId,
      'plant_catalog_id': collection.plantCatalogId,
      'custom_name': collection.customName,
      'scientific_name': collection.scientificName,
      'image_url': collection.imageUrl,
      'notes': collection.notes,
      'identification_data': collection.identificationData,
      'created_at': collection.createdAt.toIso8601String(),
      'last_cared_at': collection.lastCaredAt?.toIso8601String(),
      'reminders': collection.reminders,
      'confidence': collection.confidence,
      'synced_at': DateTime.now().toIso8601String(),
    };
  }
}