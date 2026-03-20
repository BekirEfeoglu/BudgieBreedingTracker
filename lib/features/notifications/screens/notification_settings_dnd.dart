part of 'notification_settings_screen.dart';

/// Do Not Disturb hour configuration section.
class _DndSection extends ConsumerStatefulWidget {
  const _DndSection();

  @override
  ConsumerState<_DndSection> createState() => _DndSectionState();
}

class _DndSectionState extends ConsumerState<_DndSection> {
  late int _startHour;
  late int _endHour;

  @override
  void initState() {
    super.initState();
    final limiter = ref.read(notificationRateLimiterProvider);
    _startHour = limiter.dndStartHour;
    _endHour = limiter.dndEndHour;
  }

  Future<void> _pickHour({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: isStart ? _startHour : _endHour, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    final limiter = ref.read(notificationRateLimiterProvider);
    if (isStart) {
      await limiter.setDndHours(startHour: picked.hour, endHour: _endHour);
      if (mounted) setState(() => _startHour = picked.hour);
    } else {
      await limiter.setDndHours(startHour: _startHour, endHour: picked.hour);
      if (mounted) setState(() => _endHour = picked.hour);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.moonStar,
                size: AppSpacing.xxl,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'notifications.dnd_title'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'notifications.dnd_description'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _DndTimeTile(
                  label: 'notifications.dnd_start'.tr(),
                  hour: _startHour,
                  onTap: () => _pickHour(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DndTimeTile(
                  label: 'notifications.dnd_end'.tr(),
                  hour: _endHour,
                  onTap: () => _pickHour(isStart: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays a single DND time value in a tappable card.
class _DndTimeTile extends StatelessWidget {
  const _DndTimeTile({
    required this.label,
    required this.hour,
    required this.onTap,
  });

  final String label;
  final int hour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = '${hour.toString().padLeft(2, '0')}:00';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              timeText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
