import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

/// Result of a content moderation check.
class ModerationResult {
  final bool isAllowed;
  final String? rejectionReason;

  /// When `true`, the content was allowed but server-side moderation was
  /// unavailable. The content should be flagged for manual review.
  final bool needsReview;

  const ModerationResult({
    required this.isAllowed,
    this.rejectionReason,
    this.needsReview = false,
  });

  const ModerationResult.allowed()
    : isAllowed = true,
      rejectionReason = null,
      needsReview = false;
  const ModerationResult.rejected(String reason)
    : isAllowed = false,
      rejectionReason = reason,
      needsReview = false;

  /// Content is allowed but should be queued for manual review because
  /// the server-side moderation check could not be performed.
  const ModerationResult.pendingReview()
    : isAllowed = true,
      rejectionReason = null,
      needsReview = true;
}

/// Service that checks user-generated content before publishing.
///
/// Two-layer approach:
/// 1. Client-side keyword filter (instant, offline-capable)
/// 2. Server-side Edge Function check (AI-powered, when available)
///
/// Apple App Store Guideline 1.2 requires content filtering for UGC.
class ContentModerationService {
  final EdgeFunctionClient? _edgeFunctionClient;
  static const _tag = '[ContentModeration]';

  const ContentModerationService({EdgeFunctionClient? edgeFunctionClient})
    : _edgeFunctionClient = edgeFunctionClient;

  /// Check text content (post body, comment, title) for violations.
  Future<ModerationResult> checkText(String text) async {
    // Layer 1: Client-side keyword filter
    final clientResult = _checkClientSide(text);
    if (!clientResult.isAllowed) return clientResult;

    // Layer 2: Server-side Edge Function (if available)
    return _checkServerSide(text);
  }

  // -------------------------------------------------------------------------
  // Client-side filter — basic keyword matching
  // -------------------------------------------------------------------------

  ModerationResult _checkClientSide(String text) {
    final normalized = text.toLowerCase();

    // Check against prohibited patterns
    for (final pattern in _prohibitedPatterns) {
      if (normalized.contains(pattern)) {
        AppLogger.warning(
          '$_tag Client-side filter triggered: prohibited pattern match',
        );
        return const ModerationResult.rejected('content_violation');
      }
    }

    // Check for excessive caps (spam indicator) — over 70% uppercase in
    // texts longer than 20 characters
    if (text.length > 20) {
      final upperCount = text.runes.where((r) {
        final ch = String.fromCharCode(r);
        return ch != ch.toLowerCase();
      }).length;
      if (upperCount / text.length > 0.7) {
        return const ModerationResult.rejected('excessive_caps');
      }
    }

    // Check for repeated characters (spam) — e.g. "aaaaaa"
    final repeatedCharRegex = RegExp(r'(.)\1{9,}');
    if (repeatedCharRegex.hasMatch(normalized)) {
      return const ModerationResult.rejected('spam_detected');
    }

    return const ModerationResult.allowed();
  }

  // -------------------------------------------------------------------------
  // Server-side filter — Supabase Edge Function
  // -------------------------------------------------------------------------

  Future<ModerationResult> _checkServerSide(String text) async {
    if (_edgeFunctionClient == null) {
      return const ModerationResult.allowed();
    }

    try {
      final result = await _edgeFunctionClient.invoke(
        'moderate-content',
        body: {'text': text, 'type': 'text'},
      );

      if (!result.success) {
        // Edge function unavailable — allow content but flag for manual review.
        AppLogger.warning(
          '$_tag Edge function unavailable, flagging for review',
        );
        return const ModerationResult.pendingReview();
      }

      final isAllowed = result.data?['allowed'] as bool? ?? true;
      if (!isAllowed) {
        final reason = result.data?['reason'] as String? ?? 'server_rejected';
        AppLogger.info('$_tag Server rejected content: $reason');
        return ModerationResult.rejected(reason);
      }

      return const ModerationResult.allowed();
    } catch (e, st) {
      // On error, allow content but flag for manual review.
      AppLogger.error('$_tag Server-side check failed', e, st);
      return const ModerationResult.pendingReview();
    }
  }

  // -------------------------------------------------------------------------
  // Prohibited content patterns (multilingual: TR, EN, DE)
  // -------------------------------------------------------------------------

  /// Patterns covering hate speech, slurs, violence, and spam across
  /// Turkish, English, and German. Each entry is checked via
  /// `String.contains()` on the lowercased input.
  /// Maps a moderation rejection reason to a localized error message.
  static String localizedError(String? reason) => switch (reason) {
    'excessive_caps' => 'community.moderation_caps'.tr(),
    'spam_detected' => 'community.moderation_spam'.tr(),
    _ => 'community.moderation_violation'.tr(),
  };

  static const _prohibitedPatterns = <String>[
    // Violence & threats (EN)
    'i will kill', 'death threat', 'bomb threat',
    // Violence & threats (TR)
    'seni öldürür', 'bomba atacağ',
    // Violence & threats (DE)
    'ich werde dich töten', 'bombendrohung',

    // Spam / scam patterns
    'buy followers', 'free money', 'click here to win',
    'takipçi satın', 'bedava para', 'hemen tıkla kazan',
    'follower kaufen', 'gratis geld',

    // Explicit URL spam
    'bit.ly/', 'tinyurl.com/',

    // Self-harm (EN/TR/DE)
    'how to kill yourself', 'intihar yöntemi', 'suizidmethode',
  ];
}
