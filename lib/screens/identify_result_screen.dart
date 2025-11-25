import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/identify_result.dart';
import '../theme/colors.dart';

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
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
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
                        color: AppColors.imageBg,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: AppColors.muted,
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.result.scientificName ?? '—',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
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
                        color: AppColors.primary,
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
                        ? AppColors.surfaceSuccess
                        : AppColors.surfaceError,
                    border: Border.all(
                      color: healthOk ? AppColors.primary : AppColors.danger,
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
                              ? AppColors.primary
                              : AppColors.danger,
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
                                  ?.copyWith(color: AppColors.textSecondary),
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
                    Text(
                      'Perawatan Umum',
                      style: Theme.of(context).textTheme.titleMedium,
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
                          AppColors.accent,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (ctx) {
                        final full = widget.result.description;
                        if (full == null || full.trim().isEmpty) {
                          return Text(
                            'Tidak ada deskripsi tersedia.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
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
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              if (full.length > charsLimit)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _expanded = !_expanded),
                                  child: Text(
                                    _expanded ? 'Tutup' : 'Baca Selengkapnya',
                                    style: const TextStyle(
                                      color: AppColors.primary,
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
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() => _expanded = true),
                              child: const Text(
                                'Baca Selengkapnya',
                                style: TextStyle(color: AppColors.primary),
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
                          backgroundColor: AppColors.primary,
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
                        icon: const Icon(Icons.share, color: AppColors.primary),
                        label: const Text(
                          'Bagikan',
                          style: TextStyle(color: AppColors.primary),
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
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Lihat Sumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
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
