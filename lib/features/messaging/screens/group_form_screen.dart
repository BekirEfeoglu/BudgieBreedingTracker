import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/messaging_form_providers.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  const GroupFormScreen({super.key});

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(messagingFormStateProvider);

    ref.listen<MessagingFormState>(messagingFormStateProvider, (_, state) {
      if (state.isSuccess && state.resultConversationId != null) {
        ref.read(messagingFormStateProvider.notifier).reset();
        context.pushReplacement(
          '${AppRoutes.messages}/${state.resultConversationId}',
        );
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('messaging.new_group'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'messaging.group_name'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'messaging.group_name_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'messaging.select_members'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'messaging.create_group'.tr(),
                isLoading: formState.isLoading,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    ref.read(messagingFormStateProvider.notifier).createGroupConversation(
          creatorId: userId,
          name: _nameController.text.trim(),
          participantIds: [userId],
        );
  }
}
