import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/update_status_provider.dart';

class UpdateOptionalSheet extends ConsumerWidget {
  const UpdateOptionalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const UpdateOptionalSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appVersionInfoProvider).asData?.value;
    final notes = info?.releaseNotesFor(context.locale.languageCode);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('update.title'.tr(), style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'update.optional_message'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'update.release_notes'.tr(),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(notes, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'update.update_now'.tr(),
              onPressed: () => _openStore(context, info?.storeUrl),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('update.later'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String? url) async {
    if (url == null) return;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update.store_open_failed'.tr())),
        );
      }
    } catch (e, st) {
      AppLogger.error('UpdateOptionalSheet store launch', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update.store_open_failed'.tr())),
        );
      }
    }
  }
}
