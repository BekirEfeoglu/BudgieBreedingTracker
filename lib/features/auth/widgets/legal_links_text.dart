import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';

/// Clickable Terms of Service & Privacy Policy text for auth screens.
class LegalLinksText extends StatelessWidget {
  const LegalLinksText({super.key});

  /// Opens [url] externally, awaiting the result so a launch failure (no
  /// browser / handler) is logged and surfaced instead of silently swallowed
  /// (the recognizers previously fired launchUrl fire-and-forget).
  Future<void> _openUrl(BuildContext context, String url) async {
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      AppLogger.warning('[LegalLinks] launchUrl failed for $url: $e');
    }
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('errors.cannot_open_url'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(
        AppSpacing.touchTargetMd,
        AppSpacing.touchTargetMd,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: theme.textTheme.bodySmall?.copyWith(
        decoration: TextDecoration.underline,
      ),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'auth.agree_terms_prefix'.tr(),
          style: normalStyle,
          textAlign: TextAlign.center,
        ),
        Semantics(
          link: true,
          label: 'auth.terms_of_service'.tr(),
          child: TextButton(
            onPressed: () => _openUrl(context, AppConstants.termsOfUseUrl),
            style: linkStyle,
            child: Text('auth.terms_of_service'.tr()),
          ),
        ),
        Text(
          'auth.agree_terms_and'.tr(),
          style: normalStyle,
          textAlign: TextAlign.center,
        ),
        Semantics(
          link: true,
          label: 'auth.privacy_policy'.tr(),
          child: TextButton(
            onPressed: () => _openUrl(context, AppConstants.privacyPolicyUrl),
            style: linkStyle,
            child: Text('auth.privacy_policy'.tr()),
          ),
        ),
        Text(
          'auth.agree_terms_suffix'.tr(),
          style: normalStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
