import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/treatment_guide.dart';
import '../models/identify_result.dart';
import '../models/plant_collection.dart';

class GuideService {
  final String _baseUrl;
  final Logger _logger = Logger();

  GuideService({String? baseUrl})
      : _baseUrl = baseUrl ?? (dotenv.env['ORCHESTRATOR_URL'] ?? '');

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  /// Get detailed treatment guide for a plant
  Future<TreatmentGuide> getPlantGuide(String plantId) async {
    if (!isConfigured) {
      throw StateError('ORCHESTRATOR_URL is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/guides/plant/$plantId');
    _logger.d('Fetching plant guide from: $uri');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      return TreatmentGuide.fromJson(jsonBody);
    } else if (response.statusCode == 404) {
      throw Exception('Guide not found for plant ID: $plantId');
    } else {
      throw Exception(
          'Failed to load guide: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get treatment guide for a specific disease
  Future<DiseaseGuide> getDiseaseGuide(String diseaseName) async {
    if (!isConfigured) {
      throw StateError('ORCHESTRATOR_URL is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/guides/disease/$diseaseName');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      return DiseaseGuide.fromJson(jsonBody);
    } else {
      throw Exception(
          'Failed to load disease guide: ${response.statusCode} - ${response.body}');
    }
  }

  /// Generate treatment guide from identification result
  Future<TreatmentGuide> generateGuideFromResult(IdentifyResult result) async {
    // Try to get from backend first
    if (result.id != null && result.id!.isNotEmpty) {
      try {
        return await getPlantGuide(result.id!);
      } catch (e) {
        _logger.w('Failed to fetch guide from backend: $e');
      }
    }

    // Fallback: Create guide from care information in result
    return _createGuideFromCareInfo(result);
  }

  /// Create guide from care information in IdentifyResult
  TreatmentGuide _createGuideFromCareInfo(IdentifyResult result) {
    final care = result.care ?? {};
    final steps = <GuideStep>[];

    // Add watering step if available
    if (care['watering'] != null) {
      final watering = care['watering'] as Map<String, dynamic>;
      steps.add(GuideStep(
        step: 1,
        title: 'Penyiraman',
        description: watering['text']?.toString() ??
            'Siram tanaman sesuai kebutuhan',
        durationMinutes: 5,
        materials: ['Air bersih', 'Penyiram tanaman'],
        tips: watering['citation']?.toString() ?? 'Jangan terlalu basah',
      ));
    }

    // Add light step if available
    if (care['light'] != null) {
      final light = care['light'] as Map<String, dynamic>;
      steps.add(GuideStep(
        step: steps.length + 1,
        title: 'Pencahayaan',
        description: light['text']?.toString() ??
            'Berikan pencahayaan yang cukup',
        durationMinutes: 0,
        materials: [],
        tips: light['citation']?.toString() ?? 'Sinar matahari tidak langsung',
      ));
    }

    // Add general care steps
    if (steps.isEmpty) {
      steps.addAll([
        GuideStep(
          step: 1,
          title: 'Perawatan Umum',
          description:
              'Tanaman ini membutuhkan perawatan rutin untuk tumbuh optimal.',
          durationMinutes: 10,
          materials: ['Pupuk', 'Alat perawatan'],
          tips: 'Periksa kondisi tanaman secara berkala',
        ),
      ]);
    }

    // Determine schedule based on plant type
    final schedule = <String, String>{
      'watering': 'setiap 3-4 hari',
      'fertilizing': '2 minggu sekali',
    };

    return TreatmentGuide(
      plantId: result.id ?? 'unknown',
      title: 'Panduan Perawatan ${result.commonName ?? "Tanaman"}',
      steps: steps,
      schedule: schedule,
      totalSteps: steps.length,
      estimatedTotalTime: steps.fold(
          0, (total, step) => total + step.durationMinutes),
    );
  }

  /// Save user progress in treatment guide
  Future<void> saveGuideProgress({
    required String guideId,
    required String userId,
    required int currentStep,
    required List<int> completedSteps,
    required bool isCompleted,
  }) async {
    if (!isConfigured) {
      throw StateError('ORCHESTRATOR_URL is not configured.');
    }

    final uri = Uri.parse('$_baseUrl/guides/progress');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'guide_id': guideId,
        'user_id': userId,
        'current_step': currentStep,
        'completed_steps': completedSteps,
        'is_completed': isCompleted,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to save progress: ${response.statusCode} - ${response.body}');
    }
  }

  /// Check if guide service is healthy
  Future<bool> checkHealth() async {
    if (!isConfigured) return false;

    try {
      final uri = Uri.parse('$_baseUrl/guides/health');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Guide service health check failed: $e');
      return false;
    }
  }

  /// Get treatment guide for a plant in collection
  Future<TreatmentGuide> getGuideForCollection(
      PlantCollection collection) async {
    if (collection.plantCatalogId != null &&
        collection.plantCatalogId!.isNotEmpty) {
      return await getPlantGuide(collection.plantCatalogId!);
    }

    // Fallback: Create from identification data
    if (collection.identificationData != null) {
      try {
        final data = PlantCollection.decodeIdentificationData(
            collection.identificationData);
        if (data != null) {
          final result = IdentifyResult.fromJson(data);
          return generateGuideFromResult(result);
        }
      } catch (e) {
        _logger.e('Failed to parse identification data: $e');
      }
    }

    // Ultimate fallback: generic guide
    return TreatmentGuide(
      plantId: collection.id?.toString() ?? 'generic',
      title: 'Panduan Perawatan ${collection.customName}',
      steps: [
        GuideStep(
          step: 1,
          title: 'Penyiraman Rutin',
          description:
              'Siram tanaman ketika tanah terasa kering. Jangan biarkan tanah terlalu basah.',
          durationMinutes: 5,
          materials: ['Air bersih', 'Penyiram tanaman'],
          tips: 'Gunakan air yang sudah diendapkan',
        ),
        GuideStep(
          step: 2,
          title: 'Pencahayaan Optimal',
          description: 'Tempatkan di area dengan pencahayaan tidak langsung.',
          durationMinutes: 0,
          materials: [],
          tips: 'Hindari sinar matahari langsung',
        ),
      ],
      schedule: {
        'watering': 'setiap 3-4 hari',
        'fertilizing': 'bulanan',
        'pruning': 'setiap 2 bulan',
      },
      totalSteps: 2,
      estimatedTotalTime: 5,
    );
  }
}