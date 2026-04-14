part of 'admin_user_detail_sections.dart';

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        LucideIcons.image,
        size: size / 2,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

class _EmptyAdminSection extends StatelessWidget {
  const _EmptyAdminSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('$title: ${'common.no_data'.tr()}'),
    );
  }
}

String _birdGenderLabel(String value) => switch (value) {
  'male' => 'birds.male'.tr(),
  'female' => 'birds.female'.tr(),
  _ => 'birds.unknown'.tr(),
};

String _birdStatusLabel(String value) => switch (value) {
  'alive' => 'birds.alive'.tr(),
  'dead' => 'birds.dead'.tr(),
  'sold' => 'birds.sold'.tr(),
  _ => 'common.unknown'.tr(),
};

String _breedingStatusLabel(String value) => switch (value) {
  'active' => 'breeding.status_active'.tr(),
  'ongoing' => 'breeding.status_ongoing'.tr(),
  'completed' => 'breeding.status_completed'.tr(),
  'cancelled' => 'breeding.status_cancelled'.tr(),
  _ => 'common.unknown'.tr(),
};

String _eggStatusLabel(String value) => switch (value) {
  'laid' => 'eggs.status_laid'.tr(),
  'fertile' => 'eggs.status_fertile'.tr(),
  'infertile' => 'eggs.status_infertile'.tr(),
  'hatched' => 'eggs.status_hatched'.tr(),
  'damaged' => 'eggs.status_damaged'.tr(),
  'discarded' => 'eggs.status_discarded'.tr(),
  'incubating' => 'eggs.status_incubating'.tr(),
  'empty' => 'eggs.status_empty'.tr(),
  _ => 'eggs.status_unknown'.tr(),
};

String _chickHealthLabel(String value) => switch (value) {
  'healthy' => 'chicks.status_healthy'.tr(),
  'sick' => 'chicks.status_sick'.tr(),
  'deceased' => 'chicks.status_deceased'.tr(),
  _ => 'chicks.status_unknown'.tr(),
};

String _photoEntityLabel(String value) => switch (value) {
  'bird' => 'admin.birds'.tr(),
  'egg' => 'breeding.eggs'.tr(),
  'chick' => 'chicks.title'.tr(),
  _ => 'common.unknown'.tr(),
};

String? _formatDate(BuildContext context, DateTime? date) {
  if (date == null) return null;
  return DateFormat(
    'dd MMM yyyy',
    Localizations.localeOf(context).languageCode,
  ).format(date);
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
