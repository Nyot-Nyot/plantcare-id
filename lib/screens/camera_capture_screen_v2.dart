import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../services/camera_service.dart';
import '../services/identify_service.dart';
import 'identify_result_screen.dart';

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
  // Track temporary files created by the compression pipeline so we can
  // delete them when they're no longer needed (retake / close without use).
  final Set<String> _tempFiles = <String>{};
  // When the user chooses "Use" we should preserve temp files (caller is
  // now responsible). Set this flag before popping the route.
  bool _preserveTempOnPop = false;
  static const int _kTargetBytes = 2 * 1024 * 1024; // 2MB
  static const int _kInitialCompressQuality = 90;
  static const int _kMinCompressQuality = 30;
  static const int _kCompressStep = 10;

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
      // Use shared helper to handle loading, validation and state update.
      await _withPickedFile(
        () async => await _cameraController!.takePicture(),
        cancelMessage: 'Kamera dibatalkan',
      );
      return;
    }

    // Fallback: open native camera once if controller isn't available.
    await _withPickedFile(
      () async =>
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 90),
      cancelMessage: 'Kamera dibatalkan',
    );
  }

  Future<void> _toggleFlash() async {
    // Determine the new flash mode once and reuse it. This keeps the
    // toggle logic consistent whether or not a camera controller exists.
    final newMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    if (_cameraController == null) {
      // No controller yet; just update the desired flash mode locally.
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

  /// Shared helper to handle picked/captured files: shows loading, validates image,
  /// runs compression pipeline if needed, and sets `_pickedFile` when valid.
  /// `picker` should return an `XFile?` or null when cancelled.
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

      // Basic mime/type check and dimension validation first.
      final mime = lookupMimeType(file.path);
      if (mime == null || !mime.startsWith('image/')) {
        _showMessage('Tipe file tidak didukung. Pilih gambar (jpg/png/webp).');
        return;
      }

      final dimsOk = await _validateImage(file);
      if (!dimsOk) return;

      // Attempt to compress to target size (< 2MB). If compression is not
      // needed, _compressIfNeeded will return the original file.
      final XFile finalFile = await _compressIfNeeded(file);

      // Final size check
      final int finalSize = await finalFile.length();
      if (finalSize > _kTargetBytes) {
        // If the compression created a temporary file, delete it — it didn't
        // meet the target and we shouldn't leave its artifact behind.
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

  /// Compresses the provided [file] if it exceeds the target size. Returns
  /// the original file if no compression was needed, or a new `XFile` pointing
  /// to a temporary compressed file.
  Future<XFile> _compressIfNeeded(XFile file) async {
    final int size = await file.length();
    if (size <= _kTargetBytes) return file;

    // Try progressively lower quality steps until we meet target or hit floor.
    // Preserve the original image format when possible. Note: converting
    // formats (e.g., PNG -> JPEG) may lose transparency; we prefer to keep
    // the original format so callers that rely on alpha channels are not
    // surprised.
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

    if (compressed == null) {
      // Compression failed — return original so caller can decide what to do.
      return file;
    }

    final tmp = File(
      '${Directory.systemTemp.path}/plantcare_${DateTime.now().millisecondsSinceEpoch}$outExt',
    );
    await tmp.writeAsBytes(compressed);
    // Register this temporary file so we can clean it up later if the user
    // doesn't keep the image (retake / close without using).
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

      // Show loading indicator while switching cameras.
      // Mark camera as uninitialized so UI shows the "Memulai kamera..." state.
      setState(() {
        _cameraInitialized = false;
        _loading = true;
      });

      // Dispose the old controller, but keep the reference until we replace it
      await _cameraController!.dispose();

      // Create and initialize new controller
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
      // Reset loading state on error and surface message
      if (mounted) setState(() => _loading = false);
      _showMessage('Gagal mengganti kamera: $e');
    }
  }

  @override
  void dispose() {
    // If the user did not accept the image (didn't press Use), clean up
    // any temporary files we created during compression.
    if (!_preserveTempOnPop) {
      // Fire-and-forget cleanup; don't block dispose. We try best-effort
      // to remove temp files.
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

      // Debug: print image info to help diagnose devices that return
      // unexpected dimensions.
      // Example output: "validateImage: /tmp/.. size=123456 width=1080 height=1920"
      try {
        final int size = bytes.lengthInBytes;
        // Use debugPrint so logs are visible in flutter run output.
        debugPrint(
          'validateImage: ${file.path} size=$size width=${img.width} height=${img.height}',
        );
      } catch (_) {}

      // Accept the image if at least one dimension meets the minimum.
      // Previously we rejected when either side < minDim (AND semantics were
      // accidental); that could incorrectly reject portrait images where the
      // short side is < minDim but the long side is large enough.
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

  void _retake() {
    _retakeAsync();
  }

  Future<void> _retakeAsync() async {
    if (!mounted) return;
    // If the currently picked file is one of our temp files, delete it.
    try {
      if (_pickedFile != null && _tempFiles.contains(_pickedFile!.path)) {
        final f = File(_pickedFile!.path);
        if (await f.exists()) await f.delete();
        _tempFiles.remove(_pickedFile!.path);
      }
    } catch (_) {}

    // Reset to camera preview and let the user re-frame the shot.
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

  /// Delete a tracked temp file if it exists and remove it from tracking.
  Future<void> _deleteTempFileIfTracked(String path) async {
    try {
      if (_tempFiles.contains(path)) {
        final f = File(path);
        if (await f.exists()) await f.delete();
        _tempFiles.remove(path);
      }
    } catch (_) {}
  }

  /// Attempt to clean up all tracked temporary files. This is safe to call
  /// multiple times; files already removed will be skipped.
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
                onPressed: _loading
                    ? null
                    : () => _submitPickedFile(File(_pickedFile!.path)),
                icon: const Icon(Icons.check),
                label: const Text('Use'),
              ),
            ],
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _cancelUpload,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  UploadTask? _currentUploadTask;

  void _cancelUpload() {
    try {
      _currentUploadTask?.cancel();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitPickedFile(File file) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final svc = IdentifyService();
    // Attempt to capture current device location. If unavailable or denied,
    // we proceed without location (server will still accept the image).
    double? lat;
    double? lon;
    try {
      final pos = await _getCurrentLocation();
      if (pos != null) {
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (_) {
      // Ignore location errors and continue without coordinates.
    }

    _currentUploadTask = svc.uploadImage(file, latitude: lat, longitude: lon);
    try {
      final result = await _currentUploadTask!.future;
      if (!mounted) return;
      // preserve temp file since user used it
      _preserveTempOnPop = true;
      // Navigate to result screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IdentifyResultScreen(result: result, imageFile: file),
        ),
      );
      // After returning from result screen, close camera screen as user likely completed flow
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      String msg = 'Upload / identify gagal';
      if (e is StateError) {
        msg = e.message;
      } else if (e is HttpException) {
        msg = e.message;
      } else if (e is SocketException) {
        msg =
            'Network error: ${e.message}. Pastikan backend berjalan dan ORCHESTRATOR_URL benar (emulator: 10.0.2.2).';
      } else {
        msg = 'Upload / identify gagal: $e';
      }
      _showMessage(msg);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _currentUploadTask = null;
        });
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
}
