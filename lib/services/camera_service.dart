import 'package:camera/camera.dart';

/// Simple camera helper that preloads availableCameras() once and caches
/// the result. This avoids calling platform channels from unexpected
/// lifecycle moments and reduces the chance of the "ProcessCameraProvider"
/// channel error on some devices.
class CameraService {
  static List<CameraDescription>? _cached;

  /// Call once at app startup (main) to prime the camera list.
  static Future<void> init() async {
    try {
      _cached = await availableCameras();
    } catch (_) {
      _cached = <CameraDescription>[];
    }
  }

  /// Returns cached cameras or queries them if not initialized yet.
  static Future<List<CameraDescription>> ensureInitialized() async {
    if (_cached != null) return _cached!;
    try {
      _cached = await availableCameras();
    } catch (_) {
      _cached = <CameraDescription>[];
    }
    return _cached!;
  }

  static List<CameraDescription> get cached => _cached ?? <CameraDescription>[];
}
