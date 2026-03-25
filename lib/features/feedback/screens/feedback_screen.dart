import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_form_widgets.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_history_tab.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_info_banner.dart';

/// Screen for users to submit feedback and view submission history.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  FeedbackCategory _category = FeedbackCategory.general;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersion = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _collectDeviceInfo() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
    buffer.writeln('Dart: ${Platform.version.split(' ').first}');
    buffer.writeln('Locale: ${Platform.localeName}');
    if (_appVersion != null) buffer.writeln('App: $_appVersion');
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(feedbackFormStateProvider);

    ref.listen<FeedbackFormState>(feedbackFormStateProvider, (_, state) {
      if (!mounted) return;
      if (state.isSuccess) {
        ref.read(feedbackFormStateProvider.notifier).reset();
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('feedback.success'.tr()),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        // Switch to history tab to show the submitted feedback
        _tabController.animateTo(1);
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('feedback.error'.tr())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'feedback.title'.tr(),
          iconAsset: AppIcons.comment,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const AppIcon(AppIcons.comment, size: 18),
              text: 'feedback.new_feedback'.tr(),
            ),
            Tab(
              icon: const Icon(LucideIcons.history, size: 18),
              text: 'feedback.my_submissions'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(theme, formState), const FeedbackHistoryTab()],
      ),
    );
  }

  void _resetForm() {
    _subjectController.clear();
    _messageController.clear();
    _emailController.clear();
    setState(() => _category = FeedbackCategory.general);
  }

  // ---------------------------------------------------------------------------
  // Form tab
  // ---------------------------------------------------------------------------

  Widget _buildFormTab(ThemeData theme, FeedbackFormState formState) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),

                // Category selection
                Text(
                  'feedback.category'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FeedbackCategorySelector(
                  selected: _category,
                  onChanged: (cat) => setState(() => _category = cat),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Subject field
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'feedback.subject_label'.tr(),
                    hintText: 'feedback.subject_hint'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const AppIcon(AppIcons.edit, size: 20),
                  ),
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'feedback.subject_required'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Message field
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'feedback.message_label'.tr(),
                    hintText: 'feedback.message_hint'.tr(),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'feedback.message_required'.tr();
                    }
                    if (value.trim().length < 10) {
                      return 'feedback.message_too_short'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Email field (optional)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'feedback.email_label'.tr(),
                    hintText: 'feedback.email_hint'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(LucideIcons.mail, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'feedback.email_invalid'.tr();
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Device info section
                FeedbackDeviceInfoSection(deviceInfo: _collectDeviceInfo()),

                const SizedBox(height: AppSpacing.xl),

                // Info banner
                const FeedbackInfoBanner(),

                const SizedBox(height: AppSpacing.xxl),

                // Submit button
                PrimaryButton(
                  label: 'feedback.submit'.tr(),
                  isLoading: formState.isLoading,
                  onPressed: _submit,
                  icon: const Icon(LucideIcons.send),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    AppHaptics.lightImpact();

    final email = _emailController.text.trim();
    ref
        .read(feedbackFormStateProvider.notifier)
        .submit(
          category: _category,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          email: email.isNotEmpty ? email : null,
          appVersion: _appVersion,
          deviceInfo: _collectDeviceInfo(),
        );
  }
}
