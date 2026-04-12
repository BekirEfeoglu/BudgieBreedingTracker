import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/image_safety_service.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Fake EdgeFunctionClient that overrides scanImageSafety directly.
// This mirrors the _FakeEdgeFunctionClient pattern from
// content_moderation_service_test.dart but targets image scanning.
// ---------------------------------------------------------------------------

class _FakeEdgeFunctionClient extends EdgeFunctionClient {
  final EdgeFunctionResult? _fixedResult;
  final bool shouldThrow;

  /// Captured arguments from the last scanImageSafety call.
  String? lastImageBase64;
  String? lastMimeType;

  _FakeEdgeFunctionClient({
    EdgeFunctionResult? fixedResult,
    this.shouldThrow = false,
  })  : _fixedResult = fixedResult,
        super(_MockSupabaseClient());

  @override
  Future<EdgeFunctionResult> scanImageSafety({
    required String imageBase64,
    required String mimeType,
  }) async {
    lastImageBase64 = imageBase64;
    lastMimeType = mimeType;
    if (shouldThrow) throw Exception('Network error');
    return _fixedResult ??
        const EdgeFunctionResult(success: true, data: {'safe': true});
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  /// Small test image bytes (16 bytes, well under 2MB limit).
  final testBytes = Uint8List.fromList(List.filled(16, 0xFF));

  /// Large image bytes (3 MB, exceeds the 2MB scanning threshold).
  final largeBytes = Uint8List(3 * 1024 * 1024);

  const testMimeType = 'image/png';

  group('ImageSafetyService - null client', () {
    test('rejects when EdgeFunctionClient is null (fail-closed)', () async {
      const service = ImageSafetyService();

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'safety_scan_unavailable');
    });
  });

  group('ImageSafetyService - large image', () {
    test(
        'rejects images exceeding 2MB without calling edge function',
        () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': false, 'reason': 'should_not_reach'},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: largeBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'image_too_large');
      // Edge function should not have been called.
      expect(fakeClient.lastImageBase64, isNull);
    });
  });

  group('ImageSafetyService - safe response', () {
    test('returns safe when edge function responds with safe=true', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': true},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isTrue);
      expect(result.rejectionReason, isNull);
    });
  });

  group('ImageSafetyService - unsafe response', () {
    test('returns unsafe with reason when edge function flags image', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': false, 'reason': 'nudity_detected'},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'nudity_detected');
    });
  });

  group('ImageSafetyService - edge function unavailable', () {
    test('rejects when edge function success is false (fail-closed)', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: false,
          error: 'Function not deployed',
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'safety_scan_unavailable');
    });
  });

  group('ImageSafetyService - exception handling', () {
    test('rejects when edge function throws exception (fail-closed)', () async {
      final fakeClient = _FakeEdgeFunctionClient(shouldThrow: true);
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'safety_scan_unavailable');
    });
  });

  group('ImageSafetyService - null fields in response', () {
    test('returns safe when safe field is null in response', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'some_other_field': 'value'},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      // safe field missing → defaults to true via ?? true
      expect(result.isSafe, isTrue);
      expect(result.rejectionReason, isNull);
    });

    test('uses default reason when reason field is null', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': false},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      expect(result.isSafe, isFalse);
      // Default reason when 'reason' field is null
      expect(result.rejectionReason, 'image_flagged');
    });

    test('returns safe when data is null in response', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(success: true, data: null),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      final result = await service.scanImage(
        bytes: testBytes,
        mimeType: testMimeType,
      );

      // data is null → safe field lookup returns null → defaults to true
      expect(result.isSafe, isTrue);
    });
  });

  group('ImageSafetyService - request encoding', () {
    test('sends correct base64 encoding of image bytes', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': true},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      await service.scanImage(bytes: testBytes, mimeType: testMimeType);

      final expectedBase64 = base64Encode(testBytes);
      expect(fakeClient.lastImageBase64, expectedBase64);
    });

    test('sends correct mime type to edge function', () async {
      final fakeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'safe': true},
        ),
      );
      final service = ImageSafetyService(edgeFunctionClient: fakeClient);

      await service.scanImage(bytes: testBytes, mimeType: 'image/jpeg');

      expect(fakeClient.lastMimeType, 'image/jpeg');
    });
  });

  group('ImageSafetyResult', () {
    test('safe factory creates safe result', () {
      const result = ImageSafetyResult.safe();
      expect(result.isSafe, isTrue);
      expect(result.rejectionReason, isNull);
    });

    test('unsafe factory creates unsafe result with reason', () {
      const result = ImageSafetyResult.unsafe('violence_detected');
      expect(result.isSafe, isFalse);
      expect(result.rejectionReason, 'violence_detected');
    });
  });
}
