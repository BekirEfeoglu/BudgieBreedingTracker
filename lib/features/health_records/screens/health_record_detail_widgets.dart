part of 'health_record_detail_screen.dart';

class _HeaderSection extends StatelessWidget {
  final HealthRecord record;
  final ThemeData theme;

  const _HeaderSection({required this.record, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: healthRecordTypeColor(record.type).withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: healthRecordTypeColor(
              record.type,
            ).withValues(alpha: 0.2),
            child: Icon(
              healthRecordTypeIcon(record.type),
              size: 32,
              color: healthRecordTypeColor(record.type),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            record.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            healthRecordTypeLabel(record.type),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: healthRecordTypeColor(record.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalInfoCard extends ConsumerWidget {
  final String birdId;

  const _AnimalInfoCard({required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final cache = ref.watch(animalNameCacheProvider(userId));
    final animal = cache[birdId];

    if (animal == null) return const SizedBox.shrink();

    final displayName = animal.ringNumber != null
        ? '${animal.name} (${animal.ringNumber})'
        : animal.name;
    final typeLabel = animal.isChick
        ? 'chicks.chick_label'.tr()
        : 'health_records.bird_label'.tr();

    return InfoCard(
      icon: AppIcon(animal.isChick ? AppIcons.chick : AppIcons.bird),
      title: typeLabel,
      subtitle: displayName,
      onTap: () =>
          context.push(animal.isChick ? '/chicks/$birdId' : '/birds/$birdId'),
    );
  }
}
