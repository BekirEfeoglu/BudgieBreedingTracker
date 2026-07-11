import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

/// Clickable Terms of Service & Privacy Policy text for auth screens.
class LegalLinksText extends StatefulWidget {
  const LegalLinksText({super.key});

  @override
  State<LegalLinksText> createState() => _LegalLinksTextState();
}

class _LegalLinksTextState extends State<LegalLinksText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(AppConstants.termsOfUseUrl);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl(AppConstants.privacyPolicyUrl);
  }

  /// Opens [url] externally, awaiting the result so a launch failure (no
  /// browser / handler) is logged and surfaced instead of silently swallowed
  /// (the recognizers previously fired launchUrl fire-and-forget).
  Future<void> _openUrl(String url) async {
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      AppLogger.warning('[LegalLinks] launchUrl failed for $url: $e');
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('errors.cannot_open_url'.tr())));
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final normalStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: normalStyle,
        children: [
          TextSpan(text: 'auth.agree_terms_prefix'.tr()),
          TextSpan(
            text: 'auth.terms_of_service'.tr(),
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: 'auth.agree_terms_and'.tr()),
          TextSpan(
            text: 'auth.privacy_policy'.tr(),
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          TextSpan(text: 'auth.agree_terms_suffix'.tr()),
        ],
      ),
    );
  }
}
