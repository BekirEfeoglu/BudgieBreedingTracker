import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';

/// Editable profile form with full name and avatar.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    this.initialFullName,
    this.initialAvatarUrl,
    this.email,
    required this.onSave,
    this.isLoading = false,
    this.isAvatarUploading = false,
    this.onAvatarTap,
  });

  final String? initialFullName;
  final String? initialAvatarUrl;
  final String? email;
  final Future<void> Function({required String fullName}) onSave;
  final bool isLoading;
  final bool isAvatarUploading;
  final VoidCallback? onAvatarTap;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialFullName ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar
          Center(
            child: AvatarWidget(
              imageUrl: widget.initialAvatarUrl,
              radius: 48,
              isUploading: widget.isAvatarUploading,
              onTap: widget.onAvatarTap,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Full name
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'profile.full_name'.tr(),
              helperText: 'profile.full_name_helper'.tr(),
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              prefixIcon: const AppIcon(AppIcons.profile),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'profile.full_name_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email (read-only)
          if (widget.email != null)
            TextFormField(
              initialValue: widget.email,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'profile.email'.tr(),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(LucideIcons.mail),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),

          // Save button
          PrimaryButton(
            label: 'common.save'.tr(),
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(fullName: _fullNameController.text.trim());
  }
}
