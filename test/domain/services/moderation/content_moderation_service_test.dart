import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';

import '../../../helpers/mocks.dart';

class _FakeEdgeFunctionClient extends EdgeFunctionClient {
  final EdgeFunctionResult? _fixedResult;
  final bool shouldThrow;

  _FakeEdgeFunctionClient({
    EdgeFunctionResult? fixedResult,
    this.shouldThrow = false,
  }) : _fixedResult = fixedResult,
       super(MockSupabaseClient());

  @override
  Future<EdgeFunctionResult> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return _fixedResult ??
        const EdgeFunctionResult(success: true, data: {'allowed': true});
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ContentModerationService — client-side filtering', () {
    late ContentModerationService service;

    setUp(() {
      // No edge function client → pure client-side
      service = const ContentModerationService();
    });

    test('allows normal budgie breeding content', () async {
      final result = await service.checkText(
        'My budgie just laid 5 eggs! So excited for the chicks.',
      );
      expect(result.isAllowed, isTrue);
      expect(result.rejectionReason, isNull);
    });

    test('allows Turkish budgie content', () async {
      final result = await service.checkText(
        'Muhabbet kuşum bugün 3 yumurta bıraktı, çok heyecanlıyım!',
      );
      expect(result.isAllowed, isTrue);
    });

    test('allows German budgie content', () async {
      final result = await service.checkText(
        'Mein Wellensittich hat heute 4 Eier gelegt!',
      );
      expect(result.isAllowed, isTrue);
    });

    test('rejects English violence threat', () async {
      final result = await service.checkText('I will kill you for that');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects Turkish violence threat', () async {
      final result = await service.checkText('Seni öldürürüm bak');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects German violence threat', () async {
      final result = await service.checkText('Ich werde dich töten');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects spam patterns — buy followers', () async {
      final result = await service.checkText(
        'Want more likes? Buy followers now!',
      );
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects spam patterns — Turkish spam', () async {
      final result = await service.checkText('Hemen tıkla kazan, bedava para!');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects short URL spam', () async {
      final result = await service.checkText(
        'Check this out: bit.ly/free-stuff',
      );
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('rejects excessive caps (spam indicator)', () async {
      final result = await service.checkText(
        'BUY MY PRODUCT NOW THIS IS THE BEST DEAL EVER!!!',
      );
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'excessive_caps');
    });

    test('allows short all-caps text under 20 chars', () async {
      final result = await service.checkText('GREAT NEWS!');
      expect(result.isAllowed, isTrue);
    });

    test('rejects repeated character spam', () async {
      final result = await service.checkText('This is greeeeeeeeeeat content');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'spam_detected');
    });

    test('allows reasonable repeated chars (under threshold)', () async {
      final result = await service.checkText('This is greeeat!');
      expect(result.isAllowed, isTrue);
    });

    test('allows empty-ish text', () async {
      final result = await service.checkText('');
      expect(result.isAllowed, isTrue);
    });

    test('case insensitive matching', () async {
      final result = await service.checkText('I WILL KILL someone');
      expect(result.isAllowed, isFalse);
    });
  });

  group('ContentModerationService — server-side integration', () {
    test('passes when server allows content', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'allowed': true},
        ),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Nice budgie photo!');
      expect(result.isAllowed, isTrue);
    });

    test('rejects when server rejects content', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'allowed': false, 'reason': 'inappropriate_language'},
        ),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Some content here');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'inappropriate_language');
    });

    test('flags content for review when edge function is unavailable', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: false,
          error: 'Function not deployed',
        ),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Some content');
      expect(result.isAllowed, isTrue);
      expect(result.needsReview, isTrue);
    });

    test('flags content for review when edge function throws', () async {
      final edgeClient = _FakeEdgeFunctionClient(shouldThrow: true);
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Some content');
      expect(result.isAllowed, isTrue);
      expect(result.needsReview, isTrue);
    });

    test('client-side filter runs before server-side', () async {
      // Even if server would allow, client-side should block first
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'allowed': true},
        ),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('I will kill you');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'content_violation');
    });

    test('handles null data in server response', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(success: true, data: null),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Normal content');
      expect(result.isAllowed, isTrue);
    });

    test('handles missing allowed field in server response', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'some_other_field': 'value'},
        ),
      );
      final service = ContentModerationService(edgeFunctionClient: edgeClient);

      final result = await service.checkText('Normal content');
      expect(result.isAllowed, isTrue);
    });
  });

  group('ModerationResult', () {
    test('allowed factory creates allowed result', () {
      const result = ModerationResult.allowed();
      expect(result.isAllowed, isTrue);
      expect(result.rejectionReason, isNull);
      expect(result.needsReview, isFalse);
    });

    test('rejected factory creates rejected result with reason', () {
      const result = ModerationResult.rejected('spam');
      expect(result.isAllowed, isFalse);
      expect(result.rejectionReason, 'spam');
      expect(result.needsReview, isFalse);
    });

    test('pendingReview factory creates review-flagged result', () {
      const result = ModerationResult.pendingReview();
      expect(result.isAllowed, isTrue);
      expect(result.rejectionReason, isNull);
      expect(result.needsReview, isTrue);
    });
  });
}
