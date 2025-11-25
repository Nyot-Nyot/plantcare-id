// Minimal model for identification result returned by the backend orchestrator
class IdentifyResult {
  final String? id;
  final String? commonName;
  final String? scientificName;
  final double? confidence;
  final String provider;
  final Map<String, dynamic>? rawResponse;

  IdentifyResult({
    this.id,
    this.commonName,
    this.scientificName,
    this.confidence,
    required this.provider,
    this.rawResponse,
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
    );
  }
}
