import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';

class CommunityLinkPreview extends StatelessWidget {
  final String url;

  const CommunityLinkPreview({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnyLinkPreview(
      link: url,
      displayDirection: UIDirection.uiDirectionHorizontal,
      showMultimedia: true,
      cache: const Duration(days: 7),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      errorWidget: const SizedBox.shrink(),
      boxShadow: const [],
      borderRadius: AppSpacing.radiusLg,
      removeElevation: true,
      onTap: () => _launchUrl(url),
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
      bodyStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      bodyMaxLines: 2,
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.warning('Could not launch URL: $e');
    }
  }
}
