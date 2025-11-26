import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare_id/models/identify_result.dart';
import 'package:plantcare_id/services/identify_service.dart';

/// Unit tests for IdentifyService
///
/// Note: These tests validate the service's behavior patterns and error handling.
/// Full integration tests with actual HTTP mocking would require refactoring the
/// service to use dependency injection for the http.Client. Current tests focus on:
/// - Configuration validation
/// - Parameter handling
/// - Error scenarios
/// - Cancellation support
void main() {
  group('IdentifyService', () {
    late IdentifyService service;
    const testBaseUrl = 'http://localhost:8001';

    setUp(() {
      service = IdentifyService(baseUrl: testBaseUrl);
    });

    group('Configuration', () {
      test('should accept custom baseUrl', () {
        final customService = IdentifyService(baseUrl: 'http://custom:9000');
        expect(customService, isNotNull);
      });

      test(
        'should throw StateError when baseUrl is empty for uploadImage',
        () async {
          final emptyService = IdentifyService(baseUrl: '');
          final tempDir = await Directory.systemTemp.createTemp('test_');
          final testImage = File('${tempDir.path}/test.jpg');
          await testImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

          expect(() => emptyService.uploadImage(testImage), throwsStateError);

          await testImage.delete();
          await tempDir.delete(recursive: true);
        },
      );

      test(
        'should throw StateError when baseUrl is empty for identifyByUrl',
        () {
          final emptyService = IdentifyService(baseUrl: '');
          const testUrl = 'https://example.com/plant.jpg';

          expect(() => emptyService.identifyByUrl(testUrl), throwsStateError);
        },
      );
    });

    group('uploadImage - Parameter Handling', () {
      test('should accept image file', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        await testImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header

        final task = service.uploadImage(testImage);
        expect(task, isNotNull);
        expect(task.future, isA<Future<IdentifyResult>>());
        expect(task.cancel, isA<Function>());

        // Cancel to avoid hanging test
        task.cancel();
        // Ignore the cancellation error by creating a mock result
        await task.future.catchError(
          (_) => IdentifyResult.fromJson({
            'id': 'cancelled',
            'common_name': 'Cancelled',
            'scientific_name': 'Cancelled',
            'confidence': 0.0,
            'provider': 'test',
          }),
        );

        await testImage.delete();
        await tempDir.delete(recursive: true);
      });

      test('should accept optional timeout parameter', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        await testImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(
          testImage,
          timeout: const Duration(seconds: 30),
        );
        expect(task, isNotNull);

        task.cancel();
        await task.future.catchError(
          (_) => IdentifyResult.fromJson({
            'id': 'cancelled',
            'common_name': 'Cancelled',
            'scientific_name': 'Cancelled',
            'confidence': 0.0,
            'provider': 'test',
          }),
        );

        await testImage.delete();
        await tempDir.delete(recursive: true);
      });

      test('should accept optional geolocation parameters', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        await testImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(
          testImage,
          latitude: -6.2088,
          longitude: 106.8456,
        );
        expect(task, isNotNull);

        task.cancel();
        await task.future.catchError(
          (_) => IdentifyResult.fromJson({
            'id': 'cancelled',
            'common_name': 'Cancelled',
            'scientific_name': 'Cancelled',
            'confidence': 0.0,
            'provider': 'test',
          }),
        );

        await testImage.delete();
        await tempDir.delete(recursive: true);
      });

      test('should accept checkHealth parameter', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        await testImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(testImage, checkHealth: true);
        expect(task, isNotNull);

        task.cancel();
        await task.future.catchError(
          (_) => IdentifyResult.fromJson({
            'id': 'cancelled',
            'common_name': 'Cancelled',
            'scientific_name': 'Cancelled',
            'confidence': 0.0,
            'provider': 'test',
          }),
        );

        await testImage.delete();
        await tempDir.delete(recursive: true);
      });
    });

    group('uploadImage - Error Handling', () {
      test('should handle network errors', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        testImage.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(testImage);

        // Expect network error since no server is running
        await expectLater(task.future, throwsA(isA<HttpException>()));

        testImage.deleteSync();
        tempDir.deleteSync(recursive: true);
      });

      test('should handle timeout', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        testImage.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(
          testImage,
          timeout: const Duration(milliseconds: 1),
        );

        // Expect timeout or network error
        await expectLater(
          task.future,
          throwsA(anyOf([isA<TimeoutException>(), isA<HttpException>()])),
        );

        testImage.deleteSync();
        tempDir.deleteSync(recursive: true);
      });

      test('should support cancellation', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        final testImage = File('${tempDir.path}/test.jpg');
        testImage.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]);

        final task = service.uploadImage(testImage);

        // Cancel immediately
        task.cancel();

        // Expect cancellation error
        await expectLater(task.future, throwsA(isA<StateError>()));

        testImage.deleteSync();
        tempDir.deleteSync(recursive: true);
      });
    });

    group('identifyByUrl - Parameter Handling', () {
      // Note: These tests verify API signature only. Full testing would require
      // HTTP mocking infrastructure. Error handling tests below cover actual behavior.

      test('should construct valid method signature', () {
        // Verify the method exists and accepts correct parameters
        expect(service.identifyByUrl, isA<Function>());
      });
    });

    group('identifyByUrl - Error Handling', () {
      test('should handle network errors', () async {
        const testUrl = 'https://example.com/plant.jpg';

        // Expect network error since no server is running
        await expectLater(
          service.identifyByUrl(testUrl),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle timeout', () async {
        const testUrl = 'https://example.com/plant.jpg';

        // Expect timeout
        await expectLater(
          service.identifyByUrl(
            testUrl,
            timeout: const Duration(milliseconds: 1),
          ),
          throwsA(anyOf([isA<TimeoutException>(), isA<Exception>()])),
        );
      });
    });

    group('UploadTask', () {
      test('should expose future and cancel callback', () {
        final completer = Completer<IdentifyResult>();
        var cancelCalled = false;

        final task = UploadTask(
          future: completer.future,
          cancel: () => cancelCalled = true,
        );

        expect(task.future, isA<Future<IdentifyResult>>());

        task.cancel();
        expect(cancelCalled, true);
      });

      test('should allow awaiting the future', () async {
        final completer = Completer<IdentifyResult>();

        final task = UploadTask(future: completer.future, cancel: () {});

        // Complete the future
        final mockResult = IdentifyResult.fromJson({
          'id': 'test-123',
          'common_name': 'Test Plant',
          'scientific_name': 'Testus plantus',
          'confidence': 0.9,
          'provider': 'plant.id',
        });
        completer.complete(mockResult);

        final result = await task.future;
        expect(result.id, 'test-123');
        expect(result.commonName, 'Test Plant');
      });
    });
  });
}
