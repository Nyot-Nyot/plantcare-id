import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../services/camera_service.dart';

/// Camera screen tailored for disease checking ("Cek Penyakit").
/// Visuals are aligned with the provided Figma node: centered yellow
/// pill title, dark background, corner brackets and square capture control.
class CameraDiseaseScreen extends StatefulWidget {
  const CameraDiseaseScreen({super.key});

  @override
  State<CameraDiseaseScreen> createState() => _CameraDiseaseScreenState();
}

class _CameraDiseaseScreenState extends State<CameraDiseaseScreen> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _cameraInitialized = false;
  XFile? _pickedFile;
  bool _loading = false;
  bool _openedOnStart = false;
  FlashMode _flashMode = FlashMode.off;

  static const int _kTargetBytes = 2 * 1024 * 1024; // 2MB
  static const int _kInitialCompressQuality = 90;
  static const int _kMinCompressQuality = 30;
  static const int _kCompressStep = 10;

  final Set<String> _tempFiles = <String>{};
  bool _preserveTempOnPop = false;

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
    if (_cameraController != null && _cameraInitialized) {
      await _withPickedFile(
        () async => await _cameraController!.takePicture(),
        cancelMessage: 'Kamera dibatalkan',
      );
      return;
    }

    await _withPickedFile(
      () async =>
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 90),
      cancelMessage: 'Kamera dibatalkan',
    );
  }

  Future<void> _toggleFlash() async {
    final newMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    if (_cameraController == null) {
      setState(() => _flashMode = newMode);
      return;
    }
    try {
      await _cameraController!.setFlashMode(newMode);
      if (!mounted) return;
      setState(() => _flashMode = newMode);
    } catch (e) {
      _showMessage('Gagal mengganti flash: $e');
    }
  }

  Future<void> _chooseFromGallery() async {
    if (!mounted) return;
    await _withPickedFile(
      () async => await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      ),
      cancelMessage: 'Pemilihan galeri dibatalkan',
    );
  }

  Future<void> _withPickedFile(
    Future<XFile?> Function() picker, {
    String? cancelMessage,
  }) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final XFile? file = await picker();
      if (file == null) {
        if (cancelMessage != null) _showMessage(cancelMessage);
        return;
      }

      final mime = lookupMimeType(file.path);
      if (mime == null || !mime.startsWith('image/')) {
        _showMessage('Tipe file tidak didukung. Pilih gambar (jpg/png/webp).');
        return;
      }

      final dimsOk = await _validateImage(file);
      if (!dimsOk) return;

      final XFile finalFile = await _compressIfNeeded(file);
      final int finalSize = await finalFile.length();
      if (finalSize > _kTargetBytes) {
        try {
          if (_tempFiles.contains(finalFile.path)) {
            final f = File(finalFile.path);
            if (await f.exists()) await f.delete();
            _tempFiles.remove(finalFile.path);
          }
        } catch (_) {}

        _showMessage(
          'Gagal mengompresi gambar agar kurang dari 2MB. Pilih foto lain.',
        );
        return;
      }

      if (mounted) setState(() => _pickedFile = finalFile);
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<XFile> _compressIfNeeded(XFile file) async {
    final int size = await file.length();
    if (size <= _kTargetBytes) return file;

    final String? mime = lookupMimeType(file.path);
    CompressFormat format = CompressFormat.jpeg;
    String outExt = '.jpg';
    if (mime != null) {
      if (mime.contains('png')) {
        format = CompressFormat.png;
        outExt = '.png';
      } else if (mime.contains('webp')) {
        format = CompressFormat.webp;
        outExt = '.webp';
      } else if (mime.contains('jpeg') || mime.contains('jpg')) {
        format = CompressFormat.jpeg;
        outExt = '.jpg';
      }
    }

    int quality = _kInitialCompressQuality;
    Uint8List? compressed;
    while (quality >= _kMinCompressQuality) {
      compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: quality,
        keepExif: true,
        format: format,
      );
      if (compressed == null) break;
      if (compressed.lengthInBytes <= _kTargetBytes) break;
      quality -= _kCompressStep;
    }

    if (compressed == null) return file;

    final tmp = File(
      '${Directory.systemTemp.path}/plantcare_disease_${DateTime.now().millisecondsSinceEpoch}$outExt',
    );
    await tmp.writeAsBytes(compressed);
    try {
      _tempFiles.add(tmp.path);
    } catch (_) {}
    return XFile(tmp.path);
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

      setState(() {
        _cameraInitialized = false;
        _loading = true;
      });

      await _cameraController!.dispose();

      _cameraController = CameraController(
        other,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _cameraInitialized = true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showMessage('Gagal mengganti kamera: $e');
    }
  }

  @override
  void dispose() {
    if (!_preserveTempOnPop) {
      _cleanupTempFiles();
    }
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _validateImage(XFile file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ui.Image img = await _decodeImageFromList(bytes);
      const int minDim = 800;
      try {
        final int size = bytes.lengthInBytes;
        debugPrint(
          'validateImage: ${file.path} size=$size width=${img.width} height=${img.height}',
        );
      } catch (_) {}

      if (img.width < minDim && img.height < minDim) {
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

  void _retake() => _retakeAsync();

  Future<void> _retakeAsync() async {
    if (!mounted) return;
    try {
      if (_pickedFile != null && _tempFiles.contains(_pickedFile!.path)) {
        final f = File(_pickedFile!.path);
        if (await f.exists()) await f.delete();
        _tempFiles.remove(_pickedFile!.path);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _pickedFile = null;
        _loading = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _deleteTempFileIfTracked(String path) async {
    try {
      if (_tempFiles.contains(path)) {
        final f = File(path);
        if (await f.exists()) await f.delete();
        _tempFiles.remove(path);
      }
    } catch (_) {}
  }

  Future<void> _cleanupTempFiles() async {
    final tracked = List<String>.from(_tempFiles);
    for (final p in tracked) {
      await _deleteTempFileIfTracked(p);
    }
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

            // Top bar with centered yellow pill
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
                          color: const Color(0xFFF2C94C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🔍 Cek Penyakit',
                          style: TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 14,
                          ),
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

            // Guide text
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
                    color: const Color.fromRGBO(0, 0, 0, 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Foto bagian daun atau batang yang sakit',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ),

            // Camera initializing placeholder
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

            // Bottom controls
            if (_pickedFile == null)
              Positioned.fill(
                child: Align(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _iconButton(
                              icon: Icons.photo_library,
                              onPressed: _chooseFromGallery,
                            ),
                            _squareCaptureButton(),
                            _iconButton(
                              icon: Icons.cameraswitch,
                              onPressed: _switchCamera,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Frame brackets (center)
            if (_pickedFile == null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameHeight = constraints.maxHeight * 0.45;
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

  Widget _cameraPlaceholder() => Container(color: Colors.black);

  // Circular capture button (outer ring + inner filled circle)
  Widget _squareCaptureButton() {
    return GestureDetector(
      onTap: _loading ? null : _takePhoto,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.35),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 52,
            height: 52,
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
                onPressed: () {
                  _preserveTempOnPop = true;
                  Navigator.of(context).pop(_pickedFile);
                },
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
