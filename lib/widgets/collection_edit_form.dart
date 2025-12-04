import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CollectionEditForm extends StatefulWidget {
  final String initialName;
  final String? initialNotes;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  const CollectionEditForm({
    super.key,
    required this.initialName,
    this.initialNotes,
    required this.onNameChanged,
    required this.onNotesChanged,
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  @override
  State<CollectionEditForm> createState() => _CollectionEditFormState();
}

class _CollectionEditFormState extends State<CollectionEditForm> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    
    _nameController.addListener(() {
      widget.onNameChanged(_nameController.text.trim());
    });
    
    _notesController.addListener(() {
      widget.onNotesChanged(_notesController.text.trim());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Tanaman
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Nama Tanaman',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
          ),
          child: TextFormField(
            controller: _nameController,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Masukkan nama tanaman...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLength: 50,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 20),

        // Catatan
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                'Catatan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(opsional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
          ),
          child: TextFormField(
            controller: _notesController,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan tentang tanaman ini...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            maxLines: 4,
            maxLength: 500,
            keyboardType: TextInputType.multiline,
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Aksi
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isSaving ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  'Batal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.isSaving ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Simpan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}