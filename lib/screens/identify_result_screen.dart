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

  bool? _isHealthy() {
    final h = widget.result.healthAssessment;
    if (h == null) return null;
    if (h['is_healthy'] == false) {
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

  Widget _buildLowConfidenceWarning(BuildContext context) {
    final conf = widget.result.confidence ?? 0.0;
    if (conf >= 0.7) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarning,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Akurasi Identifikasi Rendah',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hasil mungkin tidak akurat (<70%). Pastikan foto jelas, fokus, dan pencahayaan cukup.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
              ),
              child: const Text('Foto Ulang'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseList(BuildContext context) {
    final health = widget.result.healthAssessment;
    if (health == null) return const SizedBox.shrink();

    final diseasesRaw = health['diseases'];
    if (diseasesRaw is! List || diseasesRaw.isEmpty) {
      return const SizedBox.shrink();
    }
    final diseases = diseasesRaw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Kemungkinan Penyakit',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          itemCount: diseases.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = diseases[index] as Map<String, dynamic>;
            final name = d['name']?.toString() ?? 'Unknown';
            final prob = (d['probability'] as num?)?.toDouble() ?? 0.0;
            final probPct = (prob * 100).toStringAsFixed(1);
            final images = d['similar_images'] as List<dynamic>?;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (prob > 0.5
                                        ? AppColors.danger
                                        : AppColors.warning)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$probPct%',
                            style: TextStyle(
                              color: prob > 0.5
                                  ? AppColors.danger
                                  : AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prob,
                        backgroundColor: AppColors.bg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          prob > 0.5 ? AppColors.danger : AppColors.warning,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contoh Gambar: ${images?.length ?? 0} gambar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (images != null && images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, imgIndex) {
                            final imgData = images[imgIndex];
                            final imgUrl = (imgData is Map
                                ? (imgData['url_small'] ?? imgData['url'])
                                      ?.toString()
                                : null);
                            if (imgUrl == null || imgUrl.isEmpty) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceError,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No URL',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              );
                            }

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imgUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: AppColors.bg,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (_, error, stack) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: AppColors.imageBg,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppColors.muted,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Tidak ada contoh gambar tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Foto Ulang',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
              _buildLowConfidenceWarning(context),
              const SizedBox(height: 16),

              // Health box
              if (healthOk != null)
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
              if (healthOk != null) const SizedBox(height: 16),

              // Disease list (only if not healthy)
              if (healthOk == false) _buildDiseaseList(context),

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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Panduan Lengkap (stub)'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Lihat Panduan Lengkap',
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
