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
    final h = widget.result.healthAssessment;
    if (h != null && h['is_healthy'] == false) {
      return false;
    }
    return true;
  }

  // returns map title -> { 'text': ..., 'citation': ... }
  Map<String, Map<String, String?>> _extractCareFacts() {
    final care = widget.result.care;
    if (care == null) return {};

    final out = <String, Map<String, String?>>{};

    if (care['watering'] != null) {
      final w = care['watering'];
      out['Siram'] = {
        'text': w['text']?.toString(),
        'citation': w['citation']?.toString(),
      };
    }

    if (care['light'] != null) {
      final l = care['light'];
      out['Cahaya'] = {
        'text': l['text']?.toString(),
        'citation': l['citation']?.toString(),
      };
    }

    return out;
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
                      (widget.result.description != null ||
                              (widget.result.care != null &&
                                  widget.result.care!.isNotEmpty))
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
                        final full = widget.result.description;
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
            color: Colors.black.withValues(alpha: 0.03),
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
              color: color.withValues(alpha: 0.1),
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
