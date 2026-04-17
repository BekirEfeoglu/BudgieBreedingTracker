import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'community_report_reasons.dart';

/// Shows a card-based bottom sheet for the user to pick a [CommunityReportReason].
///
/// [title] is the sheet headline (e.g. "Gönderiyi Bildir").
/// Returns the selected reason, or `null` if dismissed.
Future<CommunityReportReason?> showCommunityReportSheet(
  BuildContext context, {
  required String title,
}) {
  return showAppBottomSheet<CommunityReportReason>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommunityReportSheet(title: title),
  );
}

class _CommunityReportSheet extends StatefulWidget {
  final String title;

  const _CommunityReportSheet({required this.title});

  @override
  State<_CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<_CommunityReportSheet> {
  CommunityReportReason? _selected;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _onTapReason(CommunityReportReason reason) {
    AppHaptics.selectionClick();
    setState(() => _selected = reason);
  }

  void _onSubmit() {
    if (_selected == null) return;
    AppHaptics.mediumImpact();
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Reason cards
              ...kCommunityReportReasons.map((reason) => _ReasonCard(
                    icon: iconForReportReason(reason),
                    title: titleForReportReason(reason),
                    hint: hintForReportReason(reason),
                    isSelected: _selected == reason,
                    onTap: () => _onTapReason(reason),
                  )),
              // "Other" text input
              if (_selected == CommunityReportReason.other) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: TextField(
                    controller: _otherController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'community.report_other_placeholder'.tr(),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                ),
              ],
              // Confirmation + submit button
              if (_selected != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'community.report_confirm_message'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _onSubmit,
                        child: Text('community.report_confirm'.tr()),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.75)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    LucideIcons.checkCircle2,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
