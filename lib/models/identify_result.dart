// Minimal model for identification result returned by the backend orchestrator
class IdentifyResult {
  final String? id;
  final String? commonName;
  final String? scientificName;
  final double? confidence;
  final String provider;
  final Map<String, dynamic>? rawResponse;
  final Map<String, dynamic>? care;
  final String? description;
  final Map<String, dynamic>? healthAssessment;

  IdentifyResult({
    this.id,
    this.commonName,
    this.scientificName,
    this.confidence,
    required this.provider,
    this.rawResponse,
    this.care,
    this.description,
    this.healthAssessment,
  });

  factory IdentifyResult.fromJson(Map<String, dynamic> json) {
    double? conf;
    final c = json['confidence'];
    if (c is num) conf = c.toDouble();

    return IdentifyResult(
      id: json['id']?.toString(),
      commonName: json['common_name'] is String
          ? json['common_name']
          : (json['common_name'] is List
                ? ((json['common_name'] as List).isNotEmpty
                      ? (json['common_name'] as List).first.toString()
                      : null)
                : null),
      scientificName: json['scientific_name']?.toString(),
      confidence: conf,
      provider: json['provider']?.toString() ?? 'unknown',
      rawResponse: json['raw_response'] is Map
          ? Map<String, dynamic>.from(json['raw_response'])
          : null,
      care: json['care'] is Map
          ? Map<String, dynamic>.from(json['care'])
          : null,
      description: json['description']?.toString(),
      healthAssessment: json['health_assessment'] is Map
          ? Map<String, dynamic>.from(json['health_assessment'])
          : null,
    );
  }
}
