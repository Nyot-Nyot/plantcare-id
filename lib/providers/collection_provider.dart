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
class CollectionNotifier
    extends StateNotifier<AsyncValue<List<PlantCollection>>> {
  final CollectionRepository _repository;

  CollectionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  /// Load all collections
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

      // Reload collections to update UI
      await loadCollections(userId: userId);

      return collection;
    } catch (error) {
      // Re-throw to let caller handle error
      rethrow;
    }
  }

  /// Delete a collection
  Future<void> deleteCollection(int id, {String? userId}) async {
    try {
      await _repository.deleteCollection(id);
      await loadCollections(userId: userId);
    } catch (error) {
      rethrow;
    }
  }

  /// Update collection notes
  Future<void> updateNotes(int id, String notes, {String? userId}) async {
    try {
      await _repository.updateNotes(id, notes);
      await loadCollections(userId: userId);
    } catch (error) {
      rethrow;
    }
  }

  /// Update collection custom name
  Future<void> updateCustomName(
    int id,
    String customName, {
    String? userId,
  }) async {
    try {
      await _repository.updateCustomName(id, customName);
      await loadCollections(userId: userId);
    } catch (error) {
      rethrow;
    }
  }

  /// Update last cared at timestamp
  Future<void> updateLastCaredAt(int id, {String? userId}) async {
    try {
      await _repository.updateLastCaredAt(id);
      await loadCollections(userId: userId);
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
