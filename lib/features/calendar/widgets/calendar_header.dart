import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_providers.dart';

/// Calendar header with month navigation arrows.
class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedMonth = ref.watch(displayedMonthProvider);
    final theme = Theme.of(context);

    // Use `languageCode` for the intl `DateFormat` locale (matches the
    // codebase's `event_card.dart` convention). `toStringWithSeparator()`
    // emits `tr_TR` / `en_US`, which intl tolerates today but doesn't
    // share format data with the `tr`/`en`/`de` keys used elsewhere — the
    // inconsistency is a future-formatting drift waiting to happen.
    final monthLabel = DateFormat.yMMMM(
      Localizations.localeOf(context).languageCode,
    ).format(displayedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => _changeMonth(ref, -1),
            tooltip: 'calendar.previous_month'.tr(),
            semanticLabel: 'calendar.previous_month'.tr(),
          ),
          InkWell(
            onTap: () => _goToToday(ref),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ConstrainedBox(
              // WCAG 2.5.5: explicit 48dp floor (AppSpacing.touchTargetMin is
              // 44dp, below the accessibility minimum).
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: Text(
                    monthLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppIconButton(
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: () => _changeMonth(ref, 1),
            tooltip: 'calendar.next_month'.tr(),
            semanticLabel: 'calendar.next_month'.tr(),
          ),
        ],
      ),
    );
  }

  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(displayedMonthProvider);
    ref.read(displayedMonthProvider.notifier).state = DateTime(
      current.year,
      current.month + delta,
    );
  }

  void _goToToday(WidgetRef ref) {
    final now = DateTime.now();
    ref.read(displayedMonthProvider.notifier).state = DateTime(
      now.year,
      now.month,
    );
    ref.read(selectedDateProvider.notifier).set(now);
  }
}
