import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

typedef FeedbackSaveCallback =
    Future<void> Function({
      required String status,
      String? adminResponse,
      required String priority,
    });

class FeedbackDetailSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final FeedbackSaveCallback onSave;

  const FeedbackDetailSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<FeedbackDetailSheet> {
  late final TextEditingController _responseController;
  late String _status;
  late String _priority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text: widget.item['admin_response'] as String? ?? '',
    );
    _status = widget.item['status'] as String? ?? 'open';
    _priority = widget.item['priority'] as String? ?? 'normal';
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await widget.onSave(
      status: _status,
      adminResponse: _responseController.text.trim(),
      priority: _priority,
    );
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

            // Status toggle
            Text(
              'admin.feedback_status_open'.tr(),
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
