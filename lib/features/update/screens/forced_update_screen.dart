import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../providers/update_status_provider.dart';

/// Full-screen blocker shown when local build < min_supported_build.
/// Wrapped with PopScope to prevent back-button dismissal.
class ForcedUpdateScreen extends ConsumerWidget {
  const ForcedUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appVersionInfoProvider).asData?.value;
    final notes = info?.releaseNotesFor(context.locale.languageCode);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.system_update,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'update.forced_title'.tr(),
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'update.forced_message'.tr(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    notes,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label: 'update.update_now'.tr(),
                  onPressed: () => _openStore(context, info?.storeUrl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String? url) async {
    if (url == null) return;
    // Uri.tryParse fails-soft on malformed remote `app_versions.store_url`
    // payloads. Uri.parse would throw FormatException and only the surrounding
    // try/catch would absorb it; tryParse keeps the happy path linear.
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update.store_open_failed'.tr())),
        );
      }
      return;
    }
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update.store_open_failed'.tr())),
        );
      }
    } catch (e, st) {
      AppLogger.error('ForcedUpdateScreen store launch', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update.store_open_failed'.tr())),
        );
      }
    }
  }
}
