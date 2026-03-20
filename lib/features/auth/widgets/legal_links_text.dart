import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';

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
      ..onTap = () => launchUrl(
        Uri.parse(AppConstants.termsOfUseUrl),
        mode: LaunchMode.externalApplication,
      );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(
        Uri.parse(AppConstants.privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
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
