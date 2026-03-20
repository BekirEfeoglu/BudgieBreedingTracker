import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/widgets/admin_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_user_detail_screen.dart';
import '../../features/admin/screens/admin_monitoring_screen.dart';
import '../../features/admin/screens/admin_database_screen.dart';
import '../../features/admin/screens/admin_audit_screen.dart';
import '../../features/admin/screens/admin_security_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_feedback_screen.dart';
import '../route_names.dart';

/// Admin panel routes wrapped in [AdminShell].
ShellRoute buildAdminRoutes(
  GlobalKey<NavigatorState> navigatorKey,
) => ShellRoute(
  navigatorKey: navigatorKey,
  builder: (context, state, child) => AdminShell(child: child),
  routes: [
    GoRoute(
      path: AppRoutes.adminDashboard,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminUsers,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const AdminUsersScreen()),
      routes: [
        GoRoute(
          path: ':userId',
          builder: (context, state) =>
              AdminUserDetailScreen(userId: state.pathParameters['userId']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.adminMonitoring,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminMonitoringScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminDatabase,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminDatabaseScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminAudit,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const AdminAuditScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminSecurity,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminSecurityScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminSettings,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminSettingsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminFeedback,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const AdminFeedbackScreen(),
      ),
    ),
  ],
);
