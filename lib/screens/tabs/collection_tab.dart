import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/identify_result.dart';
import '../../models/plant_collection.dart';
import '../../providers/collection_provider.dart';
import '../../screens/identify_result_screen.dart';
import '../../theme/colors.dart';

class CollectionTab extends ConsumerStatefulWidget {
  const CollectionTab({super.key});

  @override
  ConsumerState<CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends ConsumerState<CollectionTab> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load collections when tab is opened
    Future.microtask(
      () => ref.read(collectionProvider.notifier).loadCollections(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final collectionsAsync = ref.watch(collectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Koleksi Tanaman',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.surfaceBorder,
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari tanaman...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        // TODO: Implement search
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label:
                              'Semua (${collectionsAsync.value?.length ?? 0})',
                          isSelected: _selectedFilter == 'all',
                          onTap: () => setState(() => _selectedFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label:
                              '✓ Sehat (${_getHealthyCount(collectionsAsync.value)})',
                          isSelected: _selectedFilter == 'healthy',
                          onTap: () =>
                              setState(() => _selectedFilter = 'healthy'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label:
                              '⚠️ Perlu (${_getNeedsAttentionCount(collectionsAsync.value)})',
                          isSelected: _selectedFilter == 'needs_attention',
                          onTap: () => setState(
                            () => _selectedFilter = 'needs_attention',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Collection Grid
            Expanded(
              child: collectionsAsync.when(
                data: (collections) {
                  if (collections.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada koleksi',
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Identifikasi tanaman dan simpan\nke koleksi untuk mulai',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter collections based on selected filter
                  final filteredCollections = _filterCollections(collections);

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 157.5 / 254.4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredCollections.length,
                    itemBuilder: (context, index) {
                      final collection = filteredCollections[index];
                      return _CollectionCard(
                        collection: collection,
                        isHealthy: collection.isHealthy,
                        onTap: () => _navigateToDetail(collection),
                        onDelete: () => _handleDelete(collection),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to identify tab
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pindah ke tab Identify untuk menambah koleksi'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  int _getHealthyCount(List<PlantCollection>? collections) {
    if (collections == null) return 0;
    return collections.where((c) => c.isHealthy).length;
  }

  int _getNeedsAttentionCount(List<PlantCollection>? collections) {
    if (collections == null) return 0;
    return collections.where((c) => !c.isHealthy).length;
  }

  List<PlantCollection> _filterCollections(List<PlantCollection> collections) {
    switch (_selectedFilter) {
      case 'healthy':
        return collections.where((c) => c.isHealthy).toList();
      case 'needs_attention':
        return collections.where((c) => !c.isHealthy).toList();
      default:
        return collections;
    }
  }

  Future<void> _handleDelete(PlantCollection collection) async {
    // Capture ScaffoldMessenger before any async operations
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari koleksi?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus '
          '${collection.customName.isNotEmpty ? collection.customName : collection.scientificName ?? "tanaman ini"} '
          'dari koleksi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(collectionProvider.notifier)
            .deleteCollection(collection.id!);

        // Use captured messenger instead of context
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Berhasil dihapus dari koleksi'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        // Use captured messenger for error handling too
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDetail(PlantCollection collection) {
    // Capture messenger before any operations that might fail
    final messenger = ScaffoldMessenger.of(context);

    // Decode identificationData back to IdentifyResult
    if (collection.identificationData == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data identifikasi tidak tersedia'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Use model's helper method for decoding
      final data = PlantCollection.decodeIdentificationData(
        collection.identificationData,
      );
      if (data == null) {
        throw Exception('Failed to decode identification data');
      }

      final result = IdentifyResult.fromJson(data);
      final imageFile = File(collection.imageUrl);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              IdentifyResultScreen(result: result, imageFile: imageFile),
        ),
      );
    } catch (e) {
      // Use captured messenger instead of context
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error memuat data: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Collection Card Widget
class _CollectionCard extends StatelessWidget {
  final PlantCollection collection;
  final bool isHealthy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CollectionCard({
    required this.collection,
    required this.isHealthy,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECF0F1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Status Badge
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: collection.imageUrl.isNotEmpty
                        ? Image.file(
                            File(collection.imageUrl),
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                        : _buildImagePlaceholder(),
                  ),

                  // Gradient overlay for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(102),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Status Badge (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHealthy
                            ? AppColors.primary
                            : const Color(0xFFF2C94C),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHealthy ? Icons.check_circle : Icons.warning,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHealthy ? 'Sehat' : 'Perlu Perhatian',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Delete Button (top left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 14),
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        onPressed: onDelete,
                      ),
                    ),
                  ),

                  // Confidence Badge (bottom left)
                  if (collection.confidence != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${(collection.confidence! * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Plant Name
                    Text(
                      collection.customName.isNotEmpty
                          ? collection.customName
                          : collection.scientificName ?? 'Unknown Plant',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(collection.createdAt),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 140,
      color: const Color(0xFFF6F8F9),
      child: Center(
        child: Icon(
          Icons.eco_outlined,
          size: 44,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}
