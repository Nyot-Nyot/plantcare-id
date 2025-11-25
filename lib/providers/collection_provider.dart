import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/identify_result.dart';
import '../models/plant_collection.dart';
import '../services/collection_repository.dart';

/// Provider for CollectionRepository singleton
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

/// State notifier for managing collection state
///
/// ## Performance Optimization
/// This notifier uses in-memory state manipulation instead of reloading
/// from database after every operation. Benefits:
/// - Faster UI updates (no database I/O wait)
/// - Reduced database load
/// - Better UX with instant feedback
/// - Scalable for large collections
///
/// The state is only reloaded from database when:
/// - Initial load (constructor)
/// - Explicit refresh (loadCollections)
/// - Sync operations (syncCollections)
class CollectionNotifier
    extends StateNotifier<AsyncValue<List<PlantCollection>>> {
  final CollectionRepository _repository;

  CollectionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  /// Load all collections from database
  Future<void> loadCollections({String? userId}) async {
    state = const AsyncValue.loading();
    try {
      final collections = await _repository.getAllCollections(userId: userId);
      state = AsyncValue.data(collections);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Save identification result to collection
  /// Optimized: Adds to in-memory state without database reload
  Future<PlantCollection?> saveFromIdentification({
    required IdentifyResult result,
    required File imageFile,
    String? userId,
    String? customName,
    String? notes,
  }) async {
    try {
      final collection = await _repository.saveFromIdentification(
        result: result,
        imageFile: imageFile,
        userId: userId,
        customName: customName,
        notes: notes,
      );

      // ✅ Optimized: Update state in-memory instead of reloading
      state.whenData((collections) {
        // Add new collection to the beginning of the list (most recent first)
        state = AsyncValue.data([collection, ...collections]);
      });

      return collection;
    } catch (error) {
      // Re-throw to let caller handle error
      rethrow;
    }
  }

  /// Delete a collection
  /// Optimized: Removes from in-memory state without database reload
  Future<void> deleteCollection(int id, {String? userId}) async {
    try {
      await _repository.deleteCollection(id);

      // ✅ Optimized: Remove from state in-memory
      state.whenData((collections) {
        state = AsyncValue.data(
          collections.where((c) => c.id != id).toList(),
        );
      });
    } catch (error) {
      rethrow;
    }
  }

  /// Update collection notes
  /// Optimized: Updates in-memory state without database reload
  Future<void> updateNotes(int id, String notes, {String? userId}) async {
    try {
      await _repository.updateNotes(id, notes);

      // ✅ Optimized: Update specific item in state
      state.whenData((collections) {
        state = AsyncValue.data(
          collections.map((c) {
            if (c.id == id) {
              return c.copyWith(notes: notes);
            }
            return c;
          }).toList(),
        );
      });
    } catch (error) {
      rethrow;
    }
  }

  /// Update collection custom name
  /// Optimized: Updates in-memory state without database reload
  Future<void> updateCustomName(
    int id,
    String customName, {
    String? userId,
  }) async {
    try {
      await _repository.updateCustomName(id, customName);

      // ✅ Optimized: Update specific item in state
      state.whenData((collections) {
        state = AsyncValue.data(
          collections.map((c) {
            if (c.id == id) {
              return c.copyWith(customName: customName);
            }
            return c;
          }).toList(),
        );
      });
    } catch (error) {
      rethrow;
    }
  }

  /// Update last cared at timestamp
  /// Optimized: Updates in-memory state without database reload
  Future<void> updateLastCaredAt(int id, {String? userId}) async {
    try {
      await _repository.updateLastCaredAt(id);
      final now = DateTime.now();

      // ✅ Optimized: Update specific item in state
      state.whenData((collections) {
        state = AsyncValue.data(
          collections.map((c) {
            if (c.id == id) {
              return c.copyWith(lastCaredAt: now);
            }
            return c;
          }).toList(),
        );
      });
    } catch (error) {
      rethrow;
    }
  }

  /// Search collections
  Future<List<PlantCollection>> searchCollections(
    String query, {
    String? userId,
  }) async {
    try {
      return await _repository.searchCollections(query, userId: userId);
    } catch (error) {
      rethrow;
    }
  }

  /// Sync collections with backend (stub)
  Future<void> syncCollections({String? userId}) async {
    try {
      await _repository.syncCollections(userId: userId);
      // Reload after sync
      await loadCollections(userId: userId);
    } catch (error) {
      rethrow;
    }
  }
}

/// Provider for collection state management
final collectionProvider =
    StateNotifierProvider<
      CollectionNotifier,
      AsyncValue<List<PlantCollection>>
    >((ref) {
      final repository = ref.watch(collectionRepositoryProvider);
      return CollectionNotifier(repository);
    });

/// Provider to get collection count
final collectionCountProvider = FutureProvider.family<int, String?>((
  ref,
  userId,
) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return await repository.getCollectionCount(userId: userId);
});

/// Provider to get a single collection by ID
final singleCollectionProvider = FutureProvider.family<PlantCollection?, int>((
  ref,
  id,
) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return await repository.getCollectionById(id);
});
