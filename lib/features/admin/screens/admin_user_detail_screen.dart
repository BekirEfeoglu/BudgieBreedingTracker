import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_notification_sheet.dart';
import '../widgets/admin_user_detail_widgets.dart';

/// Detail screen for a specific user in admin panel.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminUserDetailProvider(widget.userId));
    final contentAsync = ref.watch(adminUserContentProvider(widget.userId));

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (state.isSuccess) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
        ref.read(adminActionsProvider.notifier).reset();
        ref.invalidate(adminUserDetailProvider(widget.userId));
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.user_detail'.tr()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) {
              final detail = ref
                  .read(adminUserDetailProvider(widget.userId))
                  .value;
              final isActive = detail?.isActive ?? true;
              return [
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Text(
                    isActive
                        ? 'admin.deactivate_user'.tr()
                        : 'admin.activate_user'.tr(),
                  ),
                ),
                PopupMenuItem(
                  value: 'send_notification',
                  child: Text('admin.send_notification'.tr()),
                ),
                PopupMenuItem(
                  value: 'export_user_data',
                  child: Text('admin.export_user_data'.tr()),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(adminUserDetailProvider(widget.userId)),
        child: detailAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () =>
                ref.invalidate(adminUserDetailProvider(widget.userId)),
          ),
          data: (detail) => UserDetailContent(
            detail: detail,
            contentAsync: contentAsync,
            onGrantPremium: () => _handleGrantPremium(),
            onRevokePremium: () => _handleRevokePremium(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    if (action == 'toggle_active') {
      final detailAsync = ref.read(adminUserDetailProvider(widget.userId));
      final currentlyActive = detailAsync.value?.isActive ?? true;

      final confirmed = await showConfirmDialog(
        context,
        title: currentlyActive
            ? 'admin.confirm_deactivate'.tr()
            : 'admin.confirm_activate'.tr(),
        message: currentlyActive
            ? 'admin.confirm_deactivate_desc'.tr()
            : 'admin.confirm_activate_desc'.tr(),
        isDestructive: currentlyActive,
      );
      if (confirmed == true) {
        ref
            .read(adminActionsProvider.notifier)
            .toggleUserActive(widget.userId, !currentlyActive);
      }
    }
    if (action == 'send_notification') {
      if (!mounted) return;
      final sent = await showAdminNotificationSheet(
        context,
        ref: ref,
        targetUserId: widget.userId,
      );
      if (sent == true && mounted) {
        final state = ref.read(adminActionsProvider);
        final message = state.successMessage ?? 'admin.notification_sent'.tr();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
    if (action == 'export_user_data') {
      await _handleExportUserData();
    }
  }

  Future<void> _handleGrantPremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_grant_premium'.tr(),
      message: 'admin.confirm_grant_premium_desc'.tr(),
    );
    if (confirmed == true) {
      ref.read(adminActionsProvider.notifier).grantPremium(widget.userId);
    }
  }

  Future<void> _handleRevokePremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_revoke_premium'.tr(),
      message: 'admin.confirm_revoke_premium_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed == true) {
      ref.read(adminActionsProvider.notifier).revokePremium(widget.userId);
    }
  }

  Future<void> _handleExportUserData() async {
    final detail = await ref.read(
      adminUserDetailProvider(widget.userId).future,
    );
    final content = await ref.read(
      adminUserContentProvider(widget.userId).future,
    );

    final payload = {
      'user': {
        'id': detail.id,
        'email': detail.email,
        'full_name': detail.fullName,
        'created_at': detail.createdAt.toIso8601String(),
        'is_active': detail.isActive,
        'subscription_plan': detail.subscriptionPlan,
        'subscription_status': detail.subscriptionStatus,
        'subscription_updated_at': detail.subscriptionUpdatedAt
            ?.toIso8601String(),
      },
      'stats': {
        'birds_count': detail.birdsCount,
        'pairs_count': detail.pairsCount,
        'eggs_count': detail.eggsCount,
        'chicks_count': detail.chicksCount,
        'health_records_count': detail.healthRecordsCount,
        'events_count': detail.eventsCount,
      },
      'birds': content.birds
          .map(
            (bird) => {
              'id': bird.id,
              'name': bird.name,
              'gender': bird.gender,
              'status': bird.status,
              'species': bird.species,
              'ring_number': bird.ringNumber,
              'cage_number': bird.cageNumber,
              'photo_url': bird.photoUrl,
              'created_at': bird.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'pairs': content.pairs
          .map(
            (pair) => {
              'id': pair.id,
              'status': pair.status,
              'male_id': pair.maleId,
              'male_name': pair.maleName,
              'female_id': pair.femaleId,
              'female_name': pair.femaleName,
              'cage_number': pair.cageNumber,
              'pairing_date': pair.pairingDate?.toIso8601String(),
              'created_at': pair.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'eggs': content.eggs
          .map(
            (egg) => {
              'id': egg.id,
              'status': egg.status,
              'egg_number': egg.eggNumber,
              'clutch_id': egg.clutchId,
              'lay_date': egg.layDate.toIso8601String(),
              'hatch_date': egg.hatchDate?.toIso8601String(),
              'photo_url': egg.photoUrl,
              'created_at': egg.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'chicks': content.chicks
          .map(
            (chick) => {
              'id': chick.id,
              'name': chick.name,
              'gender': chick.gender,
              'health_status': chick.healthStatus,
              'ring_number': chick.ringNumber,
              'hatch_date': chick.hatchDate?.toIso8601String(),
              'photo_url': chick.photoUrl,
              'bird_id': chick.birdId,
              'created_at': chick.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'photos': content.photos
          .map(
            (photo) => {
              'id': photo.id,
              'entity_type': photo.entityType,
              'entity_id': photo.entityId,
              'entity_label': photo.entityLabel,
              'file_name': photo.fileName,
              'file_path': photo.filePath,
              'is_primary': photo.isPrimary,
              'created_at': photo.createdAt?.toIso8601String(),
            },
          )
          .toList(),
    };

    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('admin.export_ready'.tr())));
  }
}
