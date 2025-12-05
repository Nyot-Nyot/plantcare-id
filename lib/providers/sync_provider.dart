import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/collection_repository.dart';
import 'collection_provider.dart';

final syncStatusProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, userId) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return await repository.getSyncStatus(userId: userId);
});

final syncConnectionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(collectionRepositoryProvider);
  return await repository.checkSyncConnection();
});

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final CollectionRepository _repository;
  
  SyncNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> syncCollections({String? userId}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.syncCollections(userId: userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(collectionRepositoryProvider);
  return SyncNotifier(repository);
});