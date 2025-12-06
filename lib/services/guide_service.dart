import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/treatment_guide.dart';

/// Service for fetching treatment guides from backend API
/// with caching support using shared_preferences (TTL: 24 hours)
class GuideService {
  final String _baseUrl;
  static const String _cachePrefix = 'guide_cache_';
  static const String _cacheTimePrefix = 'guide_cache_time_';
  static const Duration _cacheTTL = Duration(hours: 24);

  GuideService({String? baseUrl})
    : _baseUrl = baseUrl ?? dotenv.env['ORCHESTRATOR_URL'] ?? '';

  /// Get a treatment guide by its ID
  ///
  /// Returns cached version if available and not expired,
  /// otherwise fetches from API and caches the result.
  ///
  /// Throws [StateError] if ORCHESTRATOR_URL is not configured.
  /// Throws [FormatException] if API returns invalid data.
  /// Throws [Exception] if API request fails.
  Future<TreatmentGuide?> getGuideById(String id) async {
    if (_baseUrl.trim().isEmpty) {
      throw StateError(
        'ORCHESTRATOR_URL is not configured. Set ORCHESTRATOR_URL in your .env',
      );
    }

    // Check cache first
    final cachedGuide = await _getCachedGuide('id_$id');
    if (cachedGuide != null) {
      return cachedGuide;
    }

    // Fetch from API
    try {
      final uri = Uri.parse('$_baseUrl/api/guides/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body) as Map<String, dynamic>;

        // This will throw FormatException if data is invalid
        final guide = TreatmentGuide.fromJson(jsonBody);

        // Cache the result
        await _cacheGuide('id_$id', guide);

        return guide;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Failed to fetch guide: ${response.statusCode} - ${response.body}',
        );
      }
    } on FormatException catch (e) {
      throw FormatException('Invalid guide data from API: ${e.message}');
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Request timeout while fetching guide');
      }
      rethrow;
    }
  }

  /// Get treatment guides by plant ID
  ///
  /// Returns list of guides for the specified plant.
  /// Results are cached for 24 hours.
  ///
  /// [limit] - Maximum number of results (default: 10, max: 50)
  /// [offset] - Number of results to skip for pagination (default: 0)
  ///
  /// Throws [StateError] if ORCHESTRATOR_URL is not configured.
  /// Throws [FormatException] if API returns invalid data.
  /// Throws [Exception] if API request fails.
  Future<List<TreatmentGuide>> getGuidesByPlantId(
    String plantId, {
    int limit = 10,
    int offset = 0,
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw StateError(
        'ORCHESTRATOR_URL is not configured. Set ORCHESTRATOR_URL in your .env',
      );
    }

    // Validate parameters
    limit = limit.clamp(1, 50);
    offset = offset.clamp(0, 1000);

    final cacheKey = 'plant_${plantId}_limit${limit}_offset$offset';

    // Check cache first
    final cachedGuides = await _getCachedGuideList(cacheKey);
    if (cachedGuides != null) {
      return cachedGuides;
    }

    // Fetch from API
    try {
      final uri = Uri.parse('$_baseUrl/api/guides/by-plant/$plantId').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);

        List<TreatmentGuide> guides = [];
        if (jsonBody is Map && jsonBody['guides'] is List) {
          // Response format: {"guides": [...], "total": N}
          guides = (jsonBody['guides'] as List)
              .map(
                (item) => TreatmentGuide.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } else if (jsonBody is List) {
          // Direct list response
          guides = jsonBody
              .map(
                (item) => TreatmentGuide.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }

        // Cache the result
        await _cacheGuideList(cacheKey, guides);

        return guides;
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          'Failed to fetch guides: ${response.statusCode} - ${response.body}',
        );
      }
    } on FormatException catch (e) {
      throw FormatException('Invalid guide data from API: ${e.message}');
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Request timeout while fetching guides');
      }
      rethrow;
    }
  }

  /// Clear all cached guides
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  /// Clear cache for a specific guide
  Future<void> clearGuideCache(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cachePrefix}id_$id');
      await prefs.remove('${_cacheTimePrefix}id_$id');
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  // Private helper: Get cached guide
  Future<TreatmentGuide?> _getCachedGuide(String key) async {
    return _getCachedItem<TreatmentGuide>(
      key,
      (jsonMap) => TreatmentGuide.fromJson(jsonMap),
    );
  }

  // Private helper: Get cached guide list
  Future<List<TreatmentGuide>?> _getCachedGuideList(String key) async {
    final cachedJson = await _getCachedRawJson(key);
    if (cachedJson == null) return null;

    try {
      final jsonList = json.decode(cachedJson) as List;
      return jsonList
          .map((item) => TreatmentGuide.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  // Private helper: Generic cache retrieval with TTL validation
  /// Retrieves a cached item from SharedPreferences with automatic TTL validation.
  ///
  /// Returns null if:
  /// - Cache doesn't exist
  /// - Cache is expired (automatically removes expired cache)
  /// - Deserialization fails
  ///
  /// [key] - The cache key (without prefix)
  /// [fromJson] - Function to deserialize the JSON map to type T
  Future<T?> _getCachedItem<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cachedJson = await _getCachedRawJson(key);
    if (cachedJson == null) return null;

    try {
      final jsonMap = json.decode(cachedJson) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  // Private helper: Get raw cached JSON string with TTL validation
  /// Core caching logic: retrieves raw JSON string from cache if valid.
  /// Handles TTL checking and automatic cleanup of expired cache.
  Future<String?> _getCachedRawJson(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists and is not expired
      final cacheTimeKey = '$_cacheTimePrefix$key';
      final cachedTimeStr = prefs.getString(cacheTimeKey);

      if (cachedTimeStr != null) {
        final cachedTime = DateTime.parse(cachedTimeStr);
        final now = DateTime.now();

        if (now.difference(cachedTime) < _cacheTTL) {
          // Cache is still valid
          final cacheKey = '$_cachePrefix$key';
          return prefs.getString(cacheKey);
        } else {
          // Cache expired, remove it
          await prefs.remove('$_cachePrefix$key');
          await prefs.remove(cacheTimeKey);
        }
      }
    } catch (e) {
      // Ignore cache errors and return null
    }

    return null;
  }

  // Private helper: Cache a guide
  Future<void> _cacheGuide(String key, TreatmentGuide guide) async {
    await _cacheItem(key, guide.toJson());
  }

  // Private helper: Cache a guide list
  Future<void> _cacheGuideList(String key, List<TreatmentGuide> guides) async {
    final jsonList = guides.map((g) => g.toJson()).toList();
    await _cacheItem(key, jsonList);
  }

  // Private helper: Generic cache storage
  /// Stores a JSON-serializable item in SharedPreferences with timestamp.
  ///
  /// [key] - The cache key (without prefix)
  /// [data] - The data to cache (must be JSON-encodable)
  Future<void> _cacheItem(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(data);

      await prefs.setString('$_cachePrefix$key', jsonStr);
      await prefs.setString(
        '$_cacheTimePrefix$key',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Ignore cache errors
    }
  }
}
