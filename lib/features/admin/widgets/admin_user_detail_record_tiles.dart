part of 'admin_user_detail_sections.dart';

class _BirdRecordsList extends StatelessWidget {
  const _BirdRecordsList({required this.records});

  final List<AdminBirdRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _EmptyAdminSection(title: 'admin.birds'.tr());
    return Column(
      children: records
          .map(
            (record) => _RecordTile(
              title: record.name.isNotEmpty ? record.name : record.id,
              imageUrl: record.photoUrl,
              onTap: () => _showBirdDetailSheet(context, record),
              subtitle: [
                _birdGenderLabel(record.gender),
                _birdStatusLabel(record.status),
                if (_hasValue(record.ringNumber)) record.ringNumber!,
                if (_hasValue(record.cageNumber))
                  '${'birds.cage_number'.tr()}: ${record.cageNumber}',
              ],
              trailing: _formatDate(context, record.createdAt),
            ),
          )
          .toList(),
    );
  }
}

class _BreedingRecordsList extends StatelessWidget {
  const _BreedingRecordsList({required this.records});

  final List<AdminBreedingRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyAdminSection(title: 'breeding.title'.tr());
    }
    return Column(
      children: records
          .map(
            (record) => _RecordTile(
              title:
                  '${record.maleName ?? record.maleId ?? '—'} × ${record.femaleName ?? record.femaleId ?? '—'}',
              onTap: () => _showBreedingDetailSheet(context, record),
              subtitle: [
                _breedingStatusLabel(record.status),
                if (_hasValue(record.cageNumber))
                  '${'breeding.cage_number'.tr()}: ${record.cageNumber}',
                if (record.pairingDate != null)
                  '${'breeding.pairing_date'.tr()}: ${_formatDate(context, record.pairingDate)}',
              ],
              trailing: _formatDate(context, record.createdAt),
            ),
          )
          .toList(),
    );
  }
}

class _EggRecordsList extends StatelessWidget {
  const _EggRecordsList({required this.records});

  final List<AdminEggRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _EmptyAdminSection(title: 'breeding.eggs'.tr());
    return Column(
      children: records
          .map(
            (record) => _RecordTile(
              title: record.eggNumber != null
                  ? '${'eggs.egg_label'.tr()} #${record.eggNumber}'
                  : record.id,
              imageUrl: record.photoUrl,
              onTap: () => _showEggDetailSheet(context, record),
              subtitle: [
                _eggStatusLabel(record.status),
                '${'eggs.lay_date'.tr()}: ${_formatDate(context, record.layDate)}',
                if (record.hatchDate != null)
                  '${'chicks.hatch_date'.tr()}: ${_formatDate(context, record.hatchDate)}',
                if (_hasValue(record.clutchId)) record.clutchId!,
              ],
              trailing: _formatDate(context, record.createdAt),
            ),
          )
          .toList(),
    );
  }
}

class _ChickRecordsList extends StatelessWidget {
  const _ChickRecordsList({required this.records});

  final List<AdminChickRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _EmptyAdminSection(title: 'chicks.title'.tr());
    return Column(
      children: records
          .map(
            (record) => _RecordTile(
              title: record.name?.isNotEmpty == true ? record.name! : record.id,
              imageUrl: record.photoUrl,
              onTap: () => _showChickDetailSheet(context, record),
              subtitle: [
                _birdGenderLabel(record.gender),
                _chickHealthLabel(record.healthStatus),
                if (_hasValue(record.ringNumber))
                  '${'chicks.ring_number'.tr()}: ${record.ringNumber}',
                if (record.hatchDate != null)
                  '${'chicks.hatch_date'.tr()}: ${_formatDate(context, record.hatchDate)}',
              ],
              trailing: _formatDate(context, record.createdAt),
            ),
          )
          .toList(),
    );
  }
}

class _PhotoRecordsGrid extends StatelessWidget {
  const _PhotoRecordsGrid({required this.records});

  final List<AdminPhotoRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (records.isEmpty) return _EmptyAdminSection(title: 'birds.photos'.tr());

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final record = records[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: record.filePath != null && record.filePath!.isNotEmpty
                      ? InkWell(
                          onTap: () => _showPhotoPreview(context, record),
                          child: CachedNetworkImage(
                            imageUrl: record.filePath!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const _ImageFallback(),
                          ),
                        )
                      : const _ImageFallback(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _photoEntityLabel(record.entityType),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_hasValue(record.entityLabel))
                        Text(
                          record.entityLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      if (record.isPrimary)
                        Text(
                          'common.active'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.trailing,
    this.onTap,
  });

  final String title;
  final List<String> subtitle;
  final String? imageUrl;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const _ImageFallback(),
              ),
            )
          : const _ImageFallback(size: 44),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle.where((line) => line.isNotEmpty).join(' • '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing != null
          ? Text(trailing!, style: theme.textTheme.labelSmall)
          : null,
    );
  }
}

Future<void> _showBirdDetailSheet(
  BuildContext context,
  AdminBirdRecord record,
) {
  return _showRecordSheet(
    context,
    title: record.name.isNotEmpty ? record.name : record.id,
    imageUrl: record.photoUrl,
    chips: [
      _birdGenderLabel(record.gender),
      _birdStatusLabel(record.status),
      record.species,
    ],
    details: [
      if (_hasValue(record.ringNumber))
        ('birds.ring_number'.tr(), record.ringNumber!),
      if (_hasValue(record.cageNumber))
        ('birds.cage_number'.tr(), record.cageNumber!),
      if (record.createdAt != null)
        ('admin.created_at'.tr(), _formatDate(context, record.createdAt)!),
      ('common.type'.tr(), record.species),
    ],
  );
}

Future<void> _showBreedingDetailSheet(
  BuildContext context,
  AdminBreedingRecord record,
) {
  return _showRecordSheet(
    context,
    title:
        '${record.maleName ?? record.maleId ?? '—'} × ${record.femaleName ?? record.femaleId ?? '—'}',
    chips: [_breedingStatusLabel(record.status)],
    details: [
      ('breeding.male'.tr(), record.maleName ?? record.maleId ?? '—'),
      ('breeding.female'.tr(), record.femaleName ?? record.femaleId ?? '—'),
      if (_hasValue(record.cageNumber))
        ('breeding.cage_number'.tr(), record.cageNumber!),
      if (record.pairingDate != null)
        (
          'breeding.pairing_date'.tr(),
          _formatDate(context, record.pairingDate)!,
        ),
      if (record.createdAt != null)
        ('admin.created_at'.tr(), _formatDate(context, record.createdAt)!),
    ],
  );
}

Future<void> _showEggDetailSheet(BuildContext context, AdminEggRecord record) {
  return _showRecordSheet(
    context,
    title: record.eggNumber != null
        ? '${'eggs.egg_label'.tr()} #${record.eggNumber}'
        : record.id,
    imageUrl: record.photoUrl,
    chips: [_eggStatusLabel(record.status)],
    details: [
      ('eggs.lay_date'.tr(), _formatDate(context, record.layDate)!),
      if (record.hatchDate != null)
        ('chicks.hatch_date'.tr(), _formatDate(context, record.hatchDate)!),
      if (_hasValue(record.clutchId)) ('ID', record.clutchId!),
      if (record.createdAt != null)
        ('admin.created_at'.tr(), _formatDate(context, record.createdAt)!),
    ],
  );
}

Future<void> _showChickDetailSheet(
  BuildContext context,
  AdminChickRecord record,
) {
  return _showRecordSheet(
    context,
    title: record.name?.isNotEmpty == true ? record.name! : record.id,
    imageUrl: record.photoUrl,
    chips: [
      _birdGenderLabel(record.gender),
      _chickHealthLabel(record.healthStatus),
    ],
    details: [
      if (_hasValue(record.ringNumber))
        ('chicks.ring_number'.tr(), record.ringNumber!),
      if (record.hatchDate != null)
        ('chicks.hatch_date'.tr(), _formatDate(context, record.hatchDate)!),
      if (_hasValue(record.birdId)) ('admin.linked_bird'.tr(), record.birdId!),
      if (record.createdAt != null)
        ('admin.created_at'.tr(), _formatDate(context, record.createdAt)!),
    ],
  );
}

Future<void> _showPhotoPreview(BuildContext context, AdminPhotoRecord record) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: Text(record.entityLabel ?? record.fileName)),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: record.filePath != null && record.filePath!.isNotEmpty
                    ? InteractiveViewer(
                        child: CachedNetworkImage(
                          imageUrl: record.filePath!,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => const _ImageFallback(),
                        ),
                      )
                    : const _ImageFallback(size: 120),
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: 'admin.entity_type'.tr(),
                    value: _photoEntityLabel(record.entityType),
                  ),
                  if (_hasValue(record.entityLabel))
                    _DetailRow(
                      label: 'birds.name_label'.tr(),
                      value: record.entityLabel!,
                    ),
                  _DetailRow(
                    label: 'admin.primary_photo'.tr(),
                    value: record.isPrimary
                        ? 'common.yes'.tr()
                        : 'common.no'.tr(),
                  ),
                  if (record.createdAt != null)
                    _DetailRow(
                      label: 'admin.created_at'.tr(),
                      value: _formatDate(context, record.createdAt)!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showRecordSheet(
  BuildContext context, {
  required String title,
  required List<String> chips,
  required List<(String, String)> details,
  String? imageUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const _ImageFallback(size: 120),
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips
                    .where((chip) => chip.trim().isNotEmpty)
                    .map((chip) => Chip(label: Text(chip)))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              ...details.map(
                (detail) => _DetailRow(label: detail.$1, value: detail.$2),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    },
  );
}
