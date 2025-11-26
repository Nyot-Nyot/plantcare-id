import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';

import '../models/identify_result.dart';
import 'collection_database.dart';
import 'identify_service.dart';

/// Wrapper around IdentifyService that adds caching and offline support
/// Follows offline-first strategy from architect.md with 24-hour TTL
class CachedIdentifyService {
  final IdentifyService _identifyService;
  final CollectionDatabase _db;
  final Connectivity _connectivity;

  CachedIdentifyService({
    IdentifyService? identifyService,
    CollectionDatabase? database,
    Connectivity? connectivity,
  }) : _identifyService = identifyService ?? IdentifyService(),
       _db = database ?? CollectionDatabase.instance,
       _connectivity = connectivity ?? Connectivity();

  /// Check if device has network connectivity
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
  }

  /// Generate a unique hash for an image file
  /// Uses SHA-256 hash of file contents with streaming to avoid loading entire file in memory
  Future<String> _computeImageHash(File image) async {
    final reader = image.openRead();
    final digest = await sha256.bind(reader).first;
    return digest.toString();
  }

  /// Upload an image with caching support
  /// 1. Compute image hash
  /// 2. Check cache first
  /// 3. If cache miss or online, make API call
  /// 4. Cache the result
  /// 5. Return result with metadata
  CachedUploadTask uploadImage(
    File image, {
    Duration? timeout,
    double? latitude,
    double? longitude,
    bool checkHealth = false,
  }) {
    final task = _identifyService.uploadImage(
      image,
      timeout: timeout,
      latitude: latitude,
      longitude: longitude,
      checkHealth: checkHealth,
    );

    Future<CachedIdentifyResult> wrappedFuture() async {
      // 1. Compute image hash
      final imageHash = await _computeImageHash(image);

      // 2. Check connectivity
      final online = await isOnline;

      // 3. Try cache first
      final cachedJson = await _db.getCachedResult(imageHash);
      if (cachedJson != null) {
        final cachedResult = IdentifyResult.fromJson(
          json.decode(cachedJson) as Map<String, dynamic>,
        );
        // If offline, return cached result immediately
        if (!online) {
          return CachedIdentifyResult(
            result: cachedResult,
            fromCache: true,
            isOffline: true,
          );
        }
        // If online but cache is fresh, still use cache but indicate online
        return CachedIdentifyResult(
          result: cachedResult,
          fromCache: true,
          isOffline: false,
        );
      }

      // 4. No cache or cache expired
      if (!online) {
        throw OfflineException(
          'No internet connection and no cached result available for this image.',
        );
      }

      // 5. Make API call
      final result = await task.future;

      // 6. Cache the result
      await _db.cacheIdentifyResult(imageHash, json.encode(result.toJson()));

      // 7. Clean up expired cache entries (async, don't wait)
      _db.cleanupExpiredCache().catchError((_) => 0);

      return CachedIdentifyResult(
        result: result,
        fromCache: false,
        isOffline: false,
      );
    }

    return CachedUploadTask(future: wrappedFuture(), cancel: task.cancel);
  }

  /// Identify by URL with caching support
  /// Similar to uploadImage but for URL-based identification
  Future<CachedIdentifyResult> identifyByUrl(
    String imageUrl, {
    Duration? timeout,
    double? latitude,
    double? longitude,
  }) async {
    // Use URL itself as hash for caching
    final urlHash = sha256.convert(utf8.encode(imageUrl)).toString();

    // Check connectivity
    final online = await isOnline;

    // Try cache first
    final cachedJson = await _db.getCachedResult(urlHash);
    if (cachedJson != null) {
      final cachedResult = IdentifyResult.fromJson(
        json.decode(cachedJson) as Map<String, dynamic>,
      );
      return CachedIdentifyResult(
        result: cachedResult,
        fromCache: true,
        isOffline: !online,
      );
    }

    // No cache
    if (!online) {
      throw OfflineException(
        'No internet connection and no cached result available for this URL.',
      );
    }

    // Make API call
    final result = await _identifyService.identifyByUrl(
      imageUrl,
      timeout: timeout,
      latitude: latitude,
      longitude: longitude,
    );

    // Cache the result
    await _db.cacheIdentifyResult(urlHash, json.encode(result.toJson()));

    // Clean up expired cache entries
    _db.cleanupExpiredCache().catchError((_) => 0);

    return CachedIdentifyResult(
      result: result,
      fromCache: false,
      isOffline: false,
    );
  }

  /// Get cache statistics (for debugging/settings screen)
  Future<Map<String, int>> getCacheStats() async {
    return await _db.getCacheStats();
  }

  /// Manually clear all cached results
  Future<void> clearCache() async {
    await _db.cleanupExpiredCache();
  }
}

/// Result wrapper that includes cache metadata
class CachedIdentifyResult {
  final IdentifyResult result;
  final bool fromCache;
  final bool isOffline;

  CachedIdentifyResult({
    required this.result,
    required this.fromCache,
    required this.isOffline,
  });

  /// Helper to determine if result is stale
  /// Useful for UI indicators
  bool get isStale => fromCache && isOffline;
}

/// Wrapper for upload task with caching
class CachedUploadTask {
  final Future<CachedIdentifyResult> future;
  final void Function() cancel;

  CachedUploadTask({required this.future, required this.cancel});
}

/// Exception thrown when offline and no cache available
class OfflineException implements Exception {
  final String message;

  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}
