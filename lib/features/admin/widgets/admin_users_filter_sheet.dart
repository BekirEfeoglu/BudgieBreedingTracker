import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_models.dart';

class AdminUsersFilterSheet extends ConsumerStatefulWidget {
  final AdminUsersQuery initialQuery;
  final ValueChanged<AdminUsersQuery> onApply;

  const AdminUsersFilterSheet({
    super.key,
    required this.initialQuery,
    required this.onApply,
  });

  @override
  ConsumerState<AdminUsersFilterSheet> createState() =>
      _AdminUsersFilterSheetState();
}

class _AdminUsersFilterSheetState extends ConsumerState<AdminUsersFilterSheet> {
  late bool? _isActiveFilter;
  late bool? _isPremiumFilter;
  late DateTime? _dateRangeStart;
  late DateTime? _dateRangeEnd;

  @override
  void initState() {
    super.initState();
    _isActiveFilter = widget.initialQuery.isActiveFilter;
    _isPremiumFilter = widget.initialQuery.isPremiumFilter;
    _dateRangeStart = widget.initialQuery.dateRangeStart;
    _dateRangeEnd = widget.initialQuery.dateRangeEnd;
  }

  void _apply() {
    widget.onApply(widget.initialQuery.copyWith(
      isActiveFilter: _isActiveFilter,
      isPremiumFilter: _isPremiumFilter,
      dateRangeStart: _dateRangeStart,
      dateRangeEnd: _dateRangeEnd,
      activeTodayOnly: false, // Reset quick filters when using advanced sheet
      createdTodayOnly: false,
      onlineOnly: false,
    ));
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _isActiveFilter = null;
      _isPremiumFilter = null;
      _dateRangeStart = null;
      _dateRangeEnd = null;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRangeStart != null && _dateRangeEnd != null
          ? DateTimeRange(start: _dateRangeStart!, end: _dateRangeEnd!)
          : null,
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _dateRangeStart = picked.start;
        _dateRangeEnd = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.advanced_filters'.tr(),
                style: theme.textTheme.titleLarge,
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('common.clear').tr(),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'admin.user_status'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('common.all').tr(),
                selected: _isActiveFilter == null,
                onSelected: (val) {
                  if (val) setState(() => _isActiveFilter = null);
                },
              ),
              ChoiceChip(
                label: const Text('common.active').tr(),
                selected: _isActiveFilter == true,
                onSelected: (val) {
                  if (val) setState(() => _isActiveFilter = true);
                },
              ),
              ChoiceChip(
                label: const Text('admin.inactive').tr(),
                selected: _isActiveFilter == false,
                onSelected: (val) {
                  if (val) setState(() => _isActiveFilter = false);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'admin.subscription_plan'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('common.all').tr(),
                selected: _isPremiumFilter == null,
                onSelected: (val) {
                  if (val) setState(() => _isPremiumFilter = null);
                },
              ),
              ChoiceChip(
                label: const Text('premium.title').tr(),
                selected: _isPremiumFilter == true,
                onSelected: (val) {
                  if (val) setState(() => _isPremiumFilter = true);
                },
              ),
              ChoiceChip(
                label: const Text('admin.free_users').tr(),
                selected: _isPremiumFilter == false,
                onSelected: (val) {
                  if (val) setState(() => _isPremiumFilter = false);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'admin.registration_date'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dateRangeStart != null && _dateRangeEnd != null
                  ? '${DateFormat.yMMMd().format(_dateRangeStart!)} - ${DateFormat.yMMMd().format(_dateRangeEnd!)}'
                  : 'admin.select_date_range'.tr(),
            ),
            trailing: const AppIcon(AppIcons.calendar, size: 20),
            onTap: _pickDateRange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          if (_dateRangeStart != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _dateRangeStart = null;
                    _dateRangeEnd = null;
                  });
                },
                child: const Text('common.clear').tr(), // changed to common.clear since common.clear_date doesn't exist
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xl),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _apply,
            child: const Text('common.apply').tr(),
          ),
        ],
      ),
    );
  }
}
