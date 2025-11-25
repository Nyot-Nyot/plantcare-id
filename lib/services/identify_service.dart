import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/identify_result.dart';

/// A lightweight IdentifyService that talks to the app backend orchestrator
/// (ORCHESTRATOR_URL) which in turn calls Plant.id. It provides simple
/// upload and URL-based identify methods, plus a small cancellation helper.
class IdentifyService {
  final String _baseUrl;

  IdentifyService({String? baseUrl})
    : _baseUrl = baseUrl ?? dotenv.env['ORCHESTRATOR_URL'] ?? '';

  /// Upload an image file using multipart/form-data to the orchestrator's
  /// `/identify` endpoint. Returns an IdentifyResult on success.
  ///
  /// If [timeout] is provided the request will fail with a TimeoutException
  /// if not completed in time. The returned [UploadTask] exposes a `cancel`
  /// method that closes the underlying http client to abort the request.
  UploadTask uploadImage(
    File image, {
    Duration? timeout,
    double? latitude,
    double? longitude,
    bool checkHealth = false,
  }) {
    if (_baseUrl.trim().isEmpty) {
      throw StateError(
        'ORCHESTRATOR_URL is not configured. Set ORCHESTRATOR_URL in your .env (for example: http://10.0.2.2:8001 for Android emulator or http://localhost:8001 for desktop).',
      );
    }
    final client = http.Client();
    final completer = Completer<IdentifyResult>();
    var isCancelled = false;

    (() async {
      try {
        final baseUri = Uri.parse('$_baseUrl/identify');
        final queryParams = Map<String, String>.from(baseUri.queryParameters);
        if (checkHealth) {
          queryParams['check_health'] = 'true';
        }
        final uri = baseUri.replace(queryParameters: queryParams);

        final request = http.MultipartRequest('POST', uri);
        final stream = http.ByteStream(image.openRead());
        final length = await image.length();
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: image.path.split(Platform.pathSeparator).last,
        );
        request.files.add(multipartFile);
        // Attach optional geolocation fields if provided
        if (latitude != null) request.fields['latitude'] = latitude.toString();
        if (longitude != null) {
          request.fields['longitude'] = longitude.toString();
        }

        // Forward headers from request if needed (e.g., auth handled by backend)
        final streamed = await client
            .send(request)
            .timeout(timeout ?? const Duration(seconds: 60));
        final respStr = await streamed.stream.bytesToString();
        final status = streamed.statusCode;
        if (isCancelled) return;
        if (status >= 200 && status < 300) {
          final jsonBody = json.decode(respStr) as Map<String, dynamic>;
          print('DEBUG SERVICE: Response JSON: $jsonBody');
          print(
            'DEBUG SERVICE: health_assessment: ${jsonBody['health_assessment']}',
          );
          completer.complete(IdentifyResult.fromJson(jsonBody));
        } else {
          completer.completeError(
            HttpException('Upload failed: $status - $respStr'),
          );
        }
      } on TimeoutException catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      } on SocketException catch (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            HttpException(
              'Network error connecting to orchestrator ($_baseUrl): ${e.message}. Ensure the backend is running and ORCHESTRATOR_URL is reachable (for Android emulator use 10.0.2.2).',
            ),
          );
        }
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    })();

    void cancel() {
      isCancelled = true;
      try {
        client.close();
      } catch (_) {}
      if (!completer.isCompleted) {
        completer.completeError(StateError('Upload cancelled'));
      }
    }

    return UploadTask(future: completer.future, cancel: cancel);
  }

  /// Identify by sending a JSON body with `image_url` to the orchestrator.
  /// Returns an IdentifyResult on success.
  Future<IdentifyResult> identifyByUrl(
    String imageUrl, {
    Duration? timeout,
    double? latitude,
    double? longitude,
  }) async {
    if (_baseUrl.trim().isEmpty) {
      throw StateError(
        'ORCHESTRATOR_URL is not configured. Set ORCHESTRATOR_URL in your .env (for example: http://10.0.2.2:8001 for Android emulator or http://localhost:8001 for desktop).',
      );
    }
    final uri = Uri.parse('$_baseUrl/identify');
    final client = http.Client();
    try {
      final body = <String, dynamic>{'image_url': imageUrl};
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final resp = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(timeout ?? const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
        return IdentifyResult.fromJson(jsonBody);
      }
      throw HttpException(
        'Identify by URL failed: ${resp.statusCode} - ${resp.body}',
      );
    } finally {
      client.close();
    }
  }
}

/// Lightweight wrapper that exposes the identify future and a cancel callback.
class UploadTask {
  final Future<IdentifyResult> future;
  final void Function() cancel;

  UploadTask({required this.future, required this.cancel});
}
