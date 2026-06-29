import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

/// Generic sort bottom sheet that displays a list of sort options with a
/// check-mark next to the currently selected option.
///
/// [T] must be an enum (or any type) with a `label` getter returning a
/// localized display string.
class SortBottomSheet<T> extends StatelessWidget {
  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const SortBottomSheet({
    super.key,
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'common.sort'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                ...values.map(
                  (value) {
                    final isSelected = value == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        tileColor: isSelected
                            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                            : null,
                        leading: isSelected
                            ? Icon(
                                LucideIcons.check,
                                color: theme.colorScheme.primary,
                              )
                            : const SizedBox(width: 24),
                        title: Text(
                          labelOf(value),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () {
                          onSelected(value);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet with sort options.
///
/// Returns the selected sort value, or `null` if dismissed.
Future<void> showSortBottomSheet<T>({
  required BuildContext context,
  required List<T> values,
  required T current,
  required String Function(T) labelOf,
  required ValueChanged<T> onSelected,
}) {
  return showAppBottomSheet(
    context: context,
    builder: (_) => SortBottomSheet<T>(
      values: values,
      current: current,
      labelOf: labelOf,
      onSelected: onSelected,
    ),
  );
}
