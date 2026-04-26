import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

const _validFeedbackStatuses = {'open', 'pending', 'resolved'};
const _validFeedbackPriorities = {'low', 'normal', 'high'};
const _validFeedbackCategories = {
  'general',
  'bug',
  'billing',
  'account',
  'feature',
};

String _normalizeFeedbackValue(
  Object? value,
  Set<String> allowed,
  String fallback,
) {
  final raw = value as String?;
  if (raw == null || !allowed.contains(raw)) return fallback;
  return raw;
}

typedef FeedbackSaveCallback =
    Future<void> Function({
      required String status,
      String? adminResponse,
      required String priority,
    });

typedef FeedbackExtendedSaveCallback =
    Future<void> Function({
      required String status,
      String? adminResponse,
      required String priority,
      String? category,
      String? assignedAdminId,
      String? internalNote,
    });

class FeedbackDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final FeedbackSaveCallback onSave;
  final FeedbackExtendedSaveCallback? onSaveExtended;

  const FeedbackDetailSheet({
    super.key,
    required this.item,
    required this.onSave,
    this.onSaveExtended,
  });

  @override
  State<FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<FeedbackDetailSheet> {
  late final TextEditingController _responseController;
  late final TextEditingController _assigneeController;
  late final TextEditingController _internalNoteController;
  late String _status;
  late String _priority;
  late String _category;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text: widget.item['admin_response'] as String? ?? '',
    );
    _assigneeController = TextEditingController(
      text: widget.item['assigned_admin_id'] as String? ?? '',
    );
    _internalNoteController = TextEditingController(
      text: widget.item['internal_note'] as String? ?? '',
    );
    _status = _normalizeFeedbackValue(
      widget.item['status'],
      _validFeedbackStatuses,
      'open',
    );
    _priority = _normalizeFeedbackValue(
      widget.item['priority'],
      _validFeedbackPriorities,
      'normal',
    );
    _category = _normalizeFeedbackValue(
      widget.item['category'] ?? widget.item['type'],
      _validFeedbackCategories,
      'general',
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    _assigneeController.dispose();
    _internalNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final extended = widget.onSaveExtended;
    if (extended != null) {
      await extended(
        status: _status,
        adminResponse: _responseController.text.trim(),
        priority: _priority,
        category: _category,
        assignedAdminId: _assigneeController.text.trim(),
        internalNote: _internalNoteController.text.trim(),
      );
    } else {
      await widget.onSave(
        status: _status,
        adminResponse: _responseController.text.trim(),
        priority: _priority,
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'admin.feedback_detail'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Read-only info rows
            _InfoRow(
              label: 'admin.feedback_subject_label'.tr(),
              value: widget.item['subject'] as String? ?? '',
            ),
            _InfoRow(
              label: 'admin.feedback_message_label'.tr(),
              value: widget.item['message'] as String? ?? '',
            ),
            if ((widget.item['email'] as String?) != null)
              _InfoRow(
                label: 'admin.feedback_email_label'.tr(),
                value: widget.item['email'] as String,
              ),
            if ((widget.item['platform'] as String?) != null)
              _InfoRow(
                label: 'admin.feedback_platform_label'.tr(),
                value: widget.item['platform'] as String,
              ),
            if ((widget.item['app_version'] as String?) != null)
              _InfoRow(
                label: 'admin.feedback_version_label'.tr(),
                value: widget.item['app_version'] as String,
              ),

            const Divider(height: AppSpacing.xxl),

            // Priority selector
            Text(
              'admin.feedback_priority'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'low',
                  label: Text('admin.feedback_priority_low'.tr()),
                  icon: const Icon(LucideIcons.arrowDown, size: 14),
                ),
                ButtonSegment(
                  value: 'normal',
                  label: Text('admin.feedback_priority_normal'.tr()),
                  icon: const Icon(LucideIcons.minus, size: 14),
                ),
                ButtonSegment(
                  value: 'high',
                  label: Text('admin.feedback_priority_high'.tr()),
                  icon: const Icon(
                    LucideIcons.alertCircle,
                    size: 14,
                    color: AppColors.error,
                  ),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'admin.feedback_status'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'open',
                  label: Text('admin.feedback_status_open'.tr()),
                  icon: const Icon(LucideIcons.circle, size: 14),
                ),
                ButtonSegment(
                  value: 'pending',
                  label: Text('admin.feedback_status_pending'.tr()),
                  icon: const Icon(LucideIcons.clock3, size: 14),
                ),
                ButtonSegment(
                  value: 'resolved',
                  label: Text('admin.feedback_status_resolved'.tr()),
                  icon: const Icon(LucideIcons.checkCircle2, size: 14),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'admin.feedback_category'.tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem(
                  value: 'general',
                  child: Text(
                    'admin.feedback_category_general'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'bug',
                  child: Text(
                    'admin.feedback_category_bug'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'billing',
                  child: Text(
                    'admin.feedback_category_billing'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'account',
                  child: Text(
                    'admin.feedback_category_account'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'feature',
                  child: Text(
                    'admin.feedback_category_feature'.tr(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _category = value);
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _assigneeController,
              decoration: InputDecoration(
                labelText: 'admin.feedback_assignee'.tr(),
                hintText: 'admin.feedback_assignee_hint'.tr(),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Admin response field
            TextFormField(
              controller: _responseController,
              decoration: InputDecoration(
                labelText: 'admin.feedback_admin_response'.tr(),
                hintText: 'admin.feedback_admin_response_hint'.tr(),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _internalNoteController,
              decoration: InputDecoration(
                labelText: 'admin.feedback_internal_note'.tr(),
                hintText: 'admin.feedback_internal_note_hint'.tr(),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Save button
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(LucideIcons.save, size: 16),
              label: Text('admin.feedback_save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
