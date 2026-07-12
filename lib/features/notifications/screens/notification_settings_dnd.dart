part of 'notification_settings_screen.dart';

/// Do Not Disturb hour configuration section.
class _DndSection extends ConsumerStatefulWidget {
  const _DndSection();

  @override
  ConsumerState<_DndSection> createState() => _DndSectionState();
}

class _DndSectionState extends ConsumerState<_DndSection> {
  Future<void> _pickHour({required bool isStart}) async {
    final limiter = ref.read(notificationRateLimiterProvider);
    final currentStart = limiter.dndStartHour;
    final currentEnd = limiter.dndEndHour;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isStart ? currentStart : currentEnd,
        minute: 0,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;

    final notifier = ref.read(notificationToggleSettingsProvider.notifier);
    if (isStart) {
      await notifier.setDndHours(startHour: picked.hour, endHour: currentEnd);
    } else {
      await notifier.setDndHours(startHour: currentStart, endHour: picked.hour);
    }
    // setDndHours mutates the shared NotificationRateLimiter in place; rebuild
    // so the tiles read its new value (the limiter is a plain Provider and
    // does not notify watchers on mutation).
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Rebuild once the rate limiter finishes loading persisted DND hours from
    // SharedPreferences. Reading in initState raced that async load and could
    // freeze the tiles on 00:00 defaults over real persisted values.
    ref.watch(rateLimiterReadyProvider);
    final limiter = ref.read(notificationRateLimiterProvider);
    final startHour = limiter.dndStartHour;
    final endHour = limiter.dndEndHour;

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
                  hour: startHour,
                  onTap: () => _pickHour(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DndTimeTile(
                  label: 'notifications.dnd_end'.tr(),
                  hour: endHour,
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

    return Semantics(
      button: true,
      label: '$label $timeText',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
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
              mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }
}
