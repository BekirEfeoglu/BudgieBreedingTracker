import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Bell icon button for the AppBar that shows unread notification count
/// and navigates to the notifications screen on tap.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider(userId));
    // Use .value to preserve previous count during loading/error states
    final unreadCount = unreadAsync.value?.length ?? 0;

    return IconButton(
      onPressed: () => context.push(AppRoutes.notifications),
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touchTargetMin,
        minHeight: AppSpacing.touchTargetMin,
      ),
      icon: unreadCount > 0
          ? Badge(
              label: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10),
              ),
              child: const AppIcon(AppIcons.notification, size: 22),
            )
          : const AppIcon(AppIcons.notification, size: 22),
    );
  }
}
