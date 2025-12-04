import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/plant_collection.dart';
import '../providers/collection_provider.dart';
//import '../providers/guide_provider.dart';
import '../theme/colors.dart';
import '../screens/treatment_guide_screen.dart';
import '../widgets/collection_edit_form.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final PlantCollection collection;
  final File? imageFile;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    this.imageFile,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  String _currentName = '';
  String _currentNotes = '';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.collection.customName;
    _currentNotes = widget.collection.notes ?? '';
  }

  void _handleNameChanged(String name) {
    setState(() {
      _currentName = name;
      _hasChanges = name != widget.collection.customName ||
          _currentNotes != (widget.collection.notes ?? '');
    });
  }

  void _handleNotesChanged(String notes) {
    setState(() {
      _currentNotes = notes;
      _hasChanges = _currentName != widget.collection.customName ||
          notes != (widget.collection.notes ?? '');
    });
  }

  Future<void> _handleSave() async {
    if (!_hasChanges) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final collectionNotifier = ref.read(collectionProvider.notifier);

      // Update custom name if changed
      if (_currentName != widget.collection.customName) {
        await collectionNotifier.updateCustomName(
          widget.collection.id!,
          _currentName,
        );
      }

      // Update notes if changed
      if (_currentNotes != (widget.collection.notes ?? '')) {
        await collectionNotifier.updateNotes(
          widget.collection.id!,
          _currentNotes,
        );
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Perubahan berhasil disimpan'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _hasChanges = false;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  void _handleCancelEdit() {
    setState(() {
      _isEditing = false;
      _currentName = widget.collection.customName;
      _currentNotes = widget.collection.notes ?? '';
      _hasChanges = false;
    });
  }

  Future<void> _handleDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari koleksi?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus '
          '"${widget.collection.customName}" dari koleksi? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(collectionProvider.notifier)
            .deleteCollection(widget.collection.id!);

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Berhasil dihapus dari koleksi'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleMarkAsCared() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(collectionProvider.notifier)
          .updateLastCaredAt(widget.collection.id!);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ Tanaman ditandai sudah dirawat'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menandai: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _handleViewGuide() {
    if (widget.collection.plantCatalogId != null &&
        widget.collection.plantCatalogId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreatmentGuideScreen(
            plantId: widget.collection.plantCatalogId!,
            plantName: widget.collection.customName,
          ),
        ),
      );
    } else {
      // Fallback: create guide from identification data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreatmentGuideScreen(
            plantId: widget.collection.id?.toString() ?? 'unknown',
            plantName: widget.collection.customName,
          ),
        ),
      );
    }
  }

  Widget _buildHealthStatus() {
    final isHealthy = widget.collection.isHealthy;
    final diseases = widget.collection.diseases;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy
            ? AppColors.surfaceSuccess
            : AppColors.surfaceError,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHealthy ? AppColors.primary : AppColors.danger,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isHealthy
                      ? AppColors.primary
                      : AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isHealthy ? Icons.check : Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHealthy
                          ? 'Tanaman Sehat'
                          : 'Perlu Perhatian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isHealthy
                            ? AppColors.primary
                            : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isHealthy
                          ? 'Tidak ada penyakit terdeteksi'
                          : 'Terdeteksi ${diseases.length} penyakit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isHealthy && diseases.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Penyakit terdeteksi:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...diseases.take(2).map((disease) {
              final name = disease['name']?.toString() ?? 'Unknown';
              final prob = (disease['probability'] as num?)?.toDouble() ?? 0.0;
              final probPercent = (prob * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• $name',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ),
                    Text(
                      '$probPercent%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Koleksi' : 'Detail Koleksi',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleDelete,
            tooltip: 'Hapus',
            color: AppColors.danger,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.imageBg,
                ),
                child: widget.imageFile != null &&
                        widget.imageFile!.existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.photo_outlined,
                          size: 48,
                          color: AppColors.muted,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Edit Form or Display Info
              if (_isEditing)
                CollectionEditForm(
                  initialName: widget.collection.customName,
                  initialNotes: widget.collection.notes,
                  onNameChanged: _handleNameChanged,
                  onNotesChanged: _handleNotesChanged,
                  onSave: _handleSave,
                  onCancel: _handleCancelEdit,
                  isSaving: _isSaving,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Name
                    Text(
                      widget.collection.customName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.collection.scientificName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.collection.scientificName!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Notes
                    if (widget.collection.notes != null &&
                        widget.collection.notes!.isNotEmpty) ...[
                      Text(
                        'Catatan',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          widget.collection.notes!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Health Status
                    Text(
                      'Status Kesehatan',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHealthStatus(),
                    const SizedBox(height: 20),

                    // Info Grid
                    Text(
                      'Informasi',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _buildInfoCard(
                          'Ditambahkan',
                          _formatDate(widget.collection.createdAt),
                          Icons.calendar_today,
                        ),
                        if (widget.collection.lastCaredAt != null)
                          _buildInfoCard(
                            'Terakhir Dirawat',
                            _formatDate(widget.collection.lastCaredAt!),
                            Icons.health_and_safety,
                          ),
                        if (widget.collection.confidence != null)
                          _buildInfoCard(
                            'Akurasi',
                            '${(widget.collection.confidence! * 100).toStringAsFixed(0)}%',
                            Icons.verified,
                          ),
                        _buildInfoCard(
                          'ID Katalog',
                          widget.collection.plantCatalogId ?? 'Tidak tersedia',
                          Icons.tag,
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Action Buttons (only show when not editing)
              if (!_isEditing) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleViewGuide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    label: const Text(
                      'Lihat Panduan Perawatan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleMarkAsCared,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    icon: Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Tandai Sudah Dirawat',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}