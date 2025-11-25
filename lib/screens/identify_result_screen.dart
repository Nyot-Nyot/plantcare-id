import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/identify_result.dart';

class IdentifyResultScreen extends StatefulWidget {
  final IdentifyResult result;
  final File? imageFile;

  const IdentifyResultScreen({super.key, required this.result, this.imageFile});

  @override
  State<IdentifyResultScreen> createState() => _IdentifyResultScreenState();
}

class _IdentifyResultScreenState extends State<IdentifyResultScreen> {
  bool _expanded = false;

  bool _isHealthy() {
    try {
      final raw = widget.result.rawResponse;
      if (raw == null) return true;
      final res = raw['result'] as Map<String, dynamic>?;
      if (res == null) return true;
      final disease = res['disease'] as Map<String, dynamic>?;
      if (disease != null) {
        final suggestions = disease['suggestions'] as List<dynamic>?;
        return suggestions == null || suggestions.isEmpty;
      }
      final isHealthy = res['is_healthy'] as Map<String, dynamic>?;
      if (isHealthy != null) {
        final prob = isHealthy['probability'];
        if (prob is num) return prob.toDouble() >= 0.5;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // returns map title -> { 'text': ..., 'citation': ... }
  Map<String, Map<String, String?>> _extractCareFacts() {
    try {
      final raw = widget.result.rawResponse;
      if (raw == null) return {};
      final res = raw['result'] as Map<String, dynamic>?;
      if (res == null) return {};
      final classification = res['classification'] as Map<String, dynamic>?;
      final suggestions = classification?['suggestions'] as List<dynamic>?;
      if (suggestions == null || suggestions.isEmpty) return {};
      final top = suggestions.first as Map<String, dynamic>?;
      final details = top?['details'] as Map<String, dynamic>?;
      if (details == null) return {};

      Map<String, String?> detailTextAndCitation(dynamic v) {
        if (v == null) return {'text': null, 'citation': null};
        if (v is String) return {'text': v, 'citation': null};
        if (v is List) {
          return {
            'text': v.map((e) => e.toString()).join(', '),
            'citation': null,
          };
        }
        if (v is Map) {
          final text =
              v['value']?.toString() ??
              v['text']?.toString() ??
              v['description']?.toString();
          final citation = v['citation']?.toString();
          if (text != null) return {'text': text, 'citation': citation};
          // Avoid showing raw JSON if keys are missing
          return {'text': null, 'citation': citation};
        }
        return {'text': v.toString(), 'citation': null};
      }

      final wateringRaw = details['watering'];
      final bestWatering = detailTextAndCitation(details['best_watering']);
      String? wateringText;
      // Default to best_watering citation as it is often the source of truth
      String? wateringCitation = bestWatering['citation'];

      // 1. Try structured watering (Indonesian friendly)
      if (wateringRaw is Map) {
        final min = wateringRaw['min'];
        final max = wateringRaw['max'];
        if (min != null || max != null) {
          if (min != null && max != null) {
            wateringText = 'Kelembaban ideal: $min — $max';
          } else if (min != null) {
            wateringText = 'Kelembaban minimal: $min';
          } else {
            wateringText = 'Kelembaban hingga: $max';
          }
          // If the raw map has a citation, use it
          if (wateringRaw['citation'] != null) {
            wateringCitation = wateringRaw['citation'].toString();
          }
        }
      }

      // 2. Fallback to English text if structured failed
      if (wateringText == null &&
          bestWatering['text'] != null &&
          bestWatering['text']!.trim().isNotEmpty) {
        wateringText = bestWatering['text']!.trim();
        wateringCitation = bestWatering['citation'];
      }

      final lightLong = detailTextAndCitation(
        details['best_light_condition'] ?? details['best_light'],
      )['text'];
      String? lightShort;
      if (lightLong != null) {
        // Use the full text for the new design, just clean it up
        lightShort = lightLong.trim();
      }

      final out = <String, Map<String, String?>>{};
      if (wateringText != null && wateringText.isNotEmpty) {
        out['Siram'] = {'text': wateringText, 'citation': wateringCitation};
      }
      if (lightShort != null && lightShort.isNotEmpty) {
        out['Cahaya'] = {'text': lightShort, 'citation': null};
      }
      // Propagation removed as requested
      return out;
    } catch (_) {
      return {};
    }
  }

  void _showCitationDialog(BuildContext context, String citation) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sumber'),
        content: SingleChildScrollView(child: SelectableText(citation)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: citation));
              Navigator.of(c).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Sumber disalin')));
            },
            child: const Text('Salin'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthOk = _isHealthy();
    final care = _extractCareFacts();
    final confidencePct = ((widget.result.confidence ?? 0) * 100)
        .clamp(0, 100)
        .toInt();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top image area (larger to match design and reduce whitespace)
              SizedBox(
                height: 300,
                width: double.infinity,
                child: widget.imageFile != null
                    ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.result.commonName ?? '—',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: const Color(0xFF2C3E50)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.result.scientificName ?? '—',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF5D6D7E),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$confidencePct% Cocok',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Health box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: healthOk
                        ? const Color(0xFFE8F8F5)
                        : const Color(0xFFFDEEEE),
                    border: Border.all(
                      color: healthOk
                          ? const Color(0xFF27AE60)
                          : Colors.redAccent,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: healthOk
                              ? const Color(0xFF27AE60)
                              : Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          healthOk ? Icons.check : Icons.error_outline,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              healthOk
                                  ? 'Tanaman Terlihat Sehat'
                                  : 'Terdeteksi Potensi Penyakit',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              healthOk
                                  ? 'Tidak ada tanda penyakit terdeteksi. Lanjutkan perawatan rutin!'
                                  : 'Beberapa gejala penyakit terdeteksi. Periksa detail untuk rekomendasi.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF5D6D7E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Care cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perawatan Umum',
                      style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _careListItem(
                          'Penyiraman',
                          care['Siram'],
                          Icons.water_drop,
                          Colors.blueAccent,
                        ),
                        _careListItem(
                          'Pencahayaan',
                          care['Cahaya'],
                          Icons.wb_sunny,
                          const Color(0xFFF2C94C),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // If details contain an object-like description or
                      // extra citation info, show a more generic title.
                      (widget
                                  .result
                                  .rawResponse?['result']?['classification']?['suggestions']
                                  ?.first?['details'] !=
                              null)
                          ? 'Informasi Detail'
                          : 'Cara Menanam & Merawat',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (ctx) {
                        final full = _extractDescription();
                        if (full == null || full.trim().isEmpty) {
                          return Text(
                            'Tidak ada deskripsi tersedia.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF5D6D7E)),
                          );
                        }
                        // Truncate based on screen height so "Baca Selengkapnya" is meaningful
                        final height = MediaQuery.of(ctx).size.height;
                        // approx chars to show: roughly proportional to vertical space
                        final charsLimit = (height * 0.6).toInt();
                        if (full.length <= charsLimit || _expanded) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                full,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF5D6D7E)),
                              ),
                              const SizedBox(height: 8),
                              if (full.length > charsLimit)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _expanded = !_expanded),
                                  child: Text(
                                    _expanded ? 'Tutup' : 'Baca Selengkapnya',
                                    style: const TextStyle(
                                      color: Color(0xFF27AE60),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                        final short = full.substring(0, charsLimit).trimRight();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$short...',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: const Color(0xFF5D6D7E)),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() => _expanded = true),
                              child: const Text(
                                'Baca Selengkapnya',
                                style: TextStyle(color: Color(0xFF27AE60)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // removed duplicate external bottom-sheet button; inline expand used above
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Bottom action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Simpan ke Koleksi (stub)'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_border),
                        label: const Text('Simpan ke Koleksi'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.share, color: Color(0xFF27AE60)),
                        label: const Text(
                          'Bagikan',
                          style: TextStyle(color: Color(0xFF27AE60)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _extractDescription() {
    try {
      final raw = widget.result.rawResponse;
      final res = raw?['result'] as Map<String, dynamic>?;
      final classification = res?['classification'] as Map<String, dynamic>?;
      final suggestions = classification?['suggestions'] as List<dynamic>?;
      final top = suggestions?.first as Map<String, dynamic>?;
      final details = top?['details'] as Map<String, dynamic>?;
      if (details != null) {
        final desc =
            details['description_all'] ??
            details['description'] ??
            details['description_gpt'];
        if (desc is Map) {
          return desc['value']?.toString() ?? desc['text']?.toString();
        }
        return desc?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _careListItem(
    String title,
    Map<String, String?>? info,
    IconData icon,
    Color color,
  ) {
    final text = info?['text'] ?? '—';
    final citation = info?['citation'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5D6D7E),
                    height: 1.5,
                  ),
                ),
                if (citation != null && citation.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showCitationDialog(context, citation),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.link,
                            size: 14,
                            color: Color(0xFF27AE60),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Lihat Sumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF27AE60),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
