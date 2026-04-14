import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_providers.dart';

part 'admin_user_detail_record_tiles.dart';
part 'admin_user_detail_helpers.dart';

/// Content sections with real user-created records.
class UserDetailRecordsSection extends StatelessWidget {
  const UserDetailRecordsSection({super.key, required this.contentAsync});

  final AsyncValue<AdminUserContent> contentAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(
            'common.data_load_error'.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          data: (content) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.user_content'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _RecordsExpansionSection(
                title: 'admin.birds'.tr(),
                count: content.birds.length,
                child: _BirdRecordsList(records: content.birds),
              ),
              _RecordsExpansionSection(
                title: 'breeding.title'.tr(),
                count: content.pairs.length,
                child: _BreedingRecordsList(records: content.pairs),
              ),
              _RecordsExpansionSection(
                title: 'breeding.eggs'.tr(),
                count: content.eggs.length,
                child: _EggRecordsList(records: content.eggs),
              ),
              _RecordsExpansionSection(
                title: 'chicks.title'.tr(),
                count: content.chicks.length,
                child: _ChickRecordsList(records: content.chicks),
              ),
              _RecordsExpansionSection(
                title: 'birds.photos'.tr(),
                count: content.photos.length,
                child: _PhotoRecordsGrid(records: content.photos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordsExpansionSection extends StatelessWidget {
  const _RecordsExpansionSection({
    required this.title,
    required this.count,
    required this.child,
  });

  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      title: Text(title),
      subtitle: Text('$count'),
      children: [child],
    );
  }
}

/// Activity log section with list of admin actions.
class UserDetailActivityLogSection extends StatelessWidget {
  final List<AdminLog> logs;
  const UserDetailActivityLogSection({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.activity_log'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (logs.isEmpty)
          Text('admin.no_activity'.tr(), style: theme.textTheme.bodyMedium)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (_, i) =>
                _LogItem(key: ValueKey(logs[i].id), log: logs[i]),
          ),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  final AdminLog log;
  const _LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'admin.time'.tr(),
            child: Icon(
              LucideIcons.clock,
              size: 14,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.details != null)
                  Text(
                    log.details!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'dd MMM HH:mm',
              Localizations.localeOf(context).languageCode,
            ).format(log.createdAt),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
