import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import 'avatar_picker_sheet.dart';
import 'profile_form.dart';

/// Opens the edit profile bottom sheet.
void openEditProfileSheet(
  BuildContext context, {
  required WidgetRef ref,
  required Profile? profile,
  required String email,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => EditProfileSheet(profile: profile, email: email),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.profile,
    required this.email,
  });

  final Profile? profile;
  final String email;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarState = ref.watch(avatarUploadStateProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'profile.edit_profile'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileForm(
            initialFullName: widget.profile?.fullName,
            initialAvatarUrl: widget.profile?.avatarUrl,
            email: widget.email,
            isLoading: _isLoading,
            isAvatarUploading: avatarState.isUploading,
            onAvatarTap: () => showAvatarPickerSheet(
              context,
              ref: ref,
              hasAvatar: widget.profile?.avatarUrl != null,
            ),
            onSave: _handleSave,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _handleSave({required String fullName}) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      final current = widget.profile;
      final updatedProfile =
          (current ?? Profile(id: userId, email: widget.email)).copyWith(
            fullName: fullName.isNotEmpty ? fullName : null,
          );

      await repo.save(updatedProfile);

      if (mounted) {
        AppHaptics.mediumImpact();
        Navigator.of(context).pop();
        ActionFeedbackService.show('common.saved_successfully'.tr());
      }
    } catch (e) {
      AppLogger.error('[EditProfileSheet] Failed to save profile', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('errors.save_failed'.tr())));
      }
    }
  }
}
