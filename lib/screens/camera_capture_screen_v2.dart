import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/camera_service.dart';

/// Full-screen camera capture screen (v2).
class CameraCaptureScreenV2 extends StatefulWidget {
  const CameraCaptureScreenV2({super.key});

  @override
  State<CameraCaptureScreenV2> createState() => _CameraCaptureScreenV2State();
}

class _CameraCaptureScreenV2State extends State<CameraCaptureScreenV2> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  XFile? _pickedFile;
  bool _loading = false;
  bool _openedOnStart = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCameraIfNeeded());
  }

  void _openCameraIfNeeded() {
    if (_openedOnStart) return;
    _openedOnStart = true;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await CameraService.ensureInitialized();
      final back = cameras.isNotEmpty
          ? cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            )
          : throw Exception('No cameras');
      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      _showMessage('Tidak dapat mengakses kamera: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (!mounted) return;
    // If camera preview is available, capture using in-app camera controller.
    if (_cameraController != null && _cameraInitialized) {
      try {
        setState(() => _loading = true);
        final XFile file = await _cameraController!.takePicture();
        final ok = await _validateImage(file);
        if (ok && mounted) setState(() => _pickedFile = file);
      } catch (e) {
        _showMessage('Gagal mengambil foto: $e');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    // Fallback: open native camera once if controller isn't available.
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (file == null) {
        _showMessage('Kamera dibatalkan');
        return;
      }
      final ok = await _validateImage(file);
      if (ok && mounted) setState(() => _pickedFile = file);
    } catch (e) {
      _showMessage('Gagal mengambil foto: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) {
      // No controller yet; toggle the desired flash mode locally.
      setState(
        () => _flashMode = _flashMode == FlashMode.off
            ? FlashMode.torch
            : FlashMode.off,
      );
      return;
    }
    try {
      final newMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _cameraController!.setFlashMode(newMode);
      if (!mounted) return;
      setState(() => _flashMode = newMode);
    } catch (e) {
      _showMessage('Gagal mengganti flash: $e');
    }
  }

  Future<void> _chooseFromGallery() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) {
        _showMessage('Pemilihan galeri dibatalkan');
        return;
      }
      final ok = await _validateImage(file);
      if (ok && mounted) setState(() => _pickedFile = file);
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameraController == null) return;
    try {
      final cameras = await CameraService.ensureInitialized();
      final current = _cameraController!.description;
      final other = cameras.firstWhere(
        (c) => c.lensDirection != current.lensDirection,
        orElse: () => current,
      );
      if (other.name == current.name) return;
      await _cameraController!.dispose();
      _cameraController = CameraController(
        other,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _showMessage('Gagal mengganti kamera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _validateImage(XFile file) async {
    try {
      final int size = await file.length();
      const int maxSize = 5 * 1024 * 1024;
      if (size > maxSize) {
        _showMessage('File terlalu besar (>5MB).');
        return false;
      }

      final Uint8List bytes = await file.readAsBytes();
      final ui.Image img = await _decodeImageFromList(bytes);
      const int minDim = 800;
      if (img.width < minDim || img.height < minDim) {
        _showMessage('Resolusi gambar terlalu kecil (min ${minDim}px).');
        return false;
      }

      return true;
    } catch (_) {
      _showMessage('Validasi gambar gagal');
      return false;
    }
  }

  Future<ui.Image> _decodeImageFromList(Uint8List data) {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data, (ui.Image img) => completer.complete(img));
    return completer.future;
  }

  void _retake() {
    if (!mounted) return;
    setState(() => _pickedFile = null);
    Future.delayed(const Duration(milliseconds: 200), () => _takePhoto());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _pickedFile == null
                  ? (_cameraInitialized && _cameraController != null
                        ? CameraPreview(_cameraController!)
                        : _cameraPlaceholder())
                  : _buildPreview(),
            ),
            // Top bar (close, title pill, flash) with subtle gradient like Figma
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.7),
                      Color.fromRGBO(0, 0, 0, 0.0),
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(top: 6),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🌿 Kenali Tanaman',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.off
                              ? Icons.flash_off
                              : Icons.flash_on,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Guide text positioned under the top bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pastikan cahaya cukup dan fokus pada daun',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),

            // Camera initialization indicator (in-app). Shows while the
            // CameraController exists but hasn't finished initializing.
            if (_pickedFile == null &&
                _cameraController != null &&
                !_cameraInitialized)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Memulai kamera...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            if (_pickedFile == null)
              // Responsive controls: bottom row in portrait, vertical side column in landscape
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPortrait =
                        MediaQuery.of(context).orientation ==
                        Orientation.portrait;
                    if (isPortrait) {
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 136,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color.fromRGBO(0, 0, 0, 0.9),
                                Color.fromRGBO(0, 0, 0, 0.0),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12.0,
                                left: 20,
                                right: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _iconButton(
                                    icon: Icons.photo_library,
                                    onPressed: _chooseFromGallery,
                                  ),
                                  _captureButton(),
                                  _iconButton(
                                    icon: Icons.cameraswitch,
                                    onPressed: _switchCamera,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Landscape: vertical controls on the right side
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _iconButton(
                                icon: Icons.photo_library,
                                onPressed: _chooseFromGallery,
                              ),
                              const SizedBox(height: 20),
                              _captureButton(),
                              const SizedBox(height: 20),
                              _iconButton(
                                icon: Icons.cameraswitch,
                                onPressed: _switchCamera,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            // Frame brackets overlay: center a framed area and draw four corner brackets
            if (_pickedFile == null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPortrait =
                        MediaQuery.of(context).orientation ==
                        Orientation.portrait;
                    final frameHeight =
                        constraints.maxHeight * (isPortrait ? 0.45 : 0.6);
                    const sideOffset = 40.0;
                    final topOffset = (constraints.maxHeight - frameHeight) / 2;
                    final bottomOffset =
                        constraints.maxHeight - (topOffset + frameHeight);
                    return Stack(
                      children: [
                        Positioned(
                          left: sideOffset,
                          top: topOffset,
                          child: _cornerBracket(topLeft: true),
                        ),
                        Positioned(
                          right: sideOffset,
                          top: topOffset,
                          child: _cornerBracket(topRight: true),
                        ),
                        Positioned(
                          left: sideOffset,
                          bottom: bottomOffset,
                          child: _cornerBracket(bottomLeft: true),
                        ),
                        Positioned(
                          right: sideOffset,
                          bottom: bottomOffset,
                          child: _cornerBracket(bottomRight: true),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPlaceholder() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Empty center — actual guide text is positioned above the preview
          // as an overlay to avoid obstructing the camera view. The frame
          // brackets are rendered as overlays in the main build so they
          // remain visible whether the preview or placeholder is shown.
        ],
      ),
    );
  }

  Widget _captureButton() {
    return GestureDetector(
      onTap: _loading ? null : _takePhoto,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _cornerBracket({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    BorderSide side = const BorderSide(color: Colors.white, width: 3);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: topLeft || bottomLeft ? side : BorderSide.none,
          top: topLeft || topRight ? side : BorderSide.none,
          right: topRight || bottomRight ? side : BorderSide.none,
          bottom: bottomLeft || bottomRight ? side : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final file = File(_pickedFile!.path);
    return Stack(
      children: [
        Positioned.fill(child: Image.file(file, fit: BoxFit.contain)),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(_pickedFile),
                icon: const Icon(Icons.check),
                label: const Text('Use'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
