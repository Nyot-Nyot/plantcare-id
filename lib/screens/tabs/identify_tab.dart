import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/colors.dart';
import '../camera_capture_screen_v2.dart';

/// Identify tab — lightweight launcher for the capture flow.
///
/// Previously this was a placeholder; replace with a small UI that
/// lets the user open the Camera or Gallery flow implemented in
/// `CameraCaptureScreen`.
class IdentifyTab extends StatefulWidget {
  const IdentifyTab({super.key});

  @override
  State<IdentifyTab> createState() => _IdentifyTabState();
}

class _IdentifyTabState extends State<IdentifyTab> {
  // Note: Identify tab no longer auto-opens the camera. The BottomNav
  // will directly open the camera when the Identify icon is tapped.

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreenV2()),
    );
    if (result != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected — ready to identify')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Identify',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text('Opening camera...', style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              onPressed: _openCamera,
            ),
          ],
        ),
      ),
    );
  }
}
