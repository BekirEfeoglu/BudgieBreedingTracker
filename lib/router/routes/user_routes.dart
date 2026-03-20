import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/genealogy/screens/genealogy_screen.dart';
import '../../features/genetics/screens/genetics_calculator_screen.dart';
import '../../features/genetics/screens/genetics_history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/backup_screen.dart';
import '../../features/settings/screens/legal_document_screen.dart';
import '../../features/more/screens/user_guide_screen.dart';
import '../../features/notifications/screens/notification_list_screen.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/feedback/screens/feedback_screen.dart';
import '../../features/auth/screens/two_factor_setup_screen.dart';
import '../../features/auth/screens/two_factor_verify_screen.dart';
import '../../features/health_records/screens/health_record_list_screen.dart';
import '../../features/health_records/screens/health_record_detail_screen.dart';
import '../../features/health_records/screens/health_record_form_screen.dart';
import '../route_names.dart';

import '../../features/genetics/screens/genetics_compare_screen.dart';
import '../../features/genetics/screens/genetics_color_audit_screen.dart';
import '../../features/genetics/screens/genetics_reverse_screen.dart';

/// Premium-gated, user, 2FA, and health record routes.
List<RouteBase> buildUserRoutes() => [
  // Premium-gated routes
  GoRoute(
    path: AppRoutes.statistics,
    builder: (context, state) => const StatisticsScreen(),
  ),
  GoRoute(
    path: AppRoutes.genealogy,
    builder: (context, state) => const GenealogyScreen(),
  ),
  GoRoute(
    path: AppRoutes.genetics,
    builder: (context, state) => const GeneticsCalculatorScreen(),
  ),
  GoRoute(
    path: AppRoutes.geneticsHistory,
    builder: (context, state) => const GeneticsHistoryScreen(),
  ),
  GoRoute(
    path: AppRoutes.geneticsReverse,
    builder: (context, state) => const GeneticsReverseScreen(),
  ),
  GoRoute(
    path: AppRoutes.geneticsCompare,
    builder: (context, state) {
      final extra = state.extra as List<String>?;
      if (extra == null) return const NotFoundScreen();
      return GeneticsCompareScreen(historyIds: extra);
    },
  ),
  if (kDebugMode)
    GoRoute(
      path: AppRoutes.geneticsColorAudit,
      builder: (context, state) => const GeneticsColorAuditScreen(),
    ),

  // User routes
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: AppRoutes.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.premium,
    builder: (context, state) => const PremiumScreen(),
  ),
  GoRoute(
    path: AppRoutes.userGuide,
    builder: (context, state) => const UserGuideScreen(),
  ),
  GoRoute(
    path: AppRoutes.notifications,
    builder: (context, state) => const NotificationListScreen(),
  ),
  GoRoute(
    path: AppRoutes.notificationSettings,
    builder: (context, state) => const NotificationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.backup,
    builder: (context, state) => const BackupScreen(),
  ),
  GoRoute(
    path: AppRoutes.feedback,
    builder: (context, state) => const FeedbackScreen(),
  ),
  GoRoute(
    path: AppRoutes.privacyPolicy,
    builder: (context, state) =>
        const LegalDocumentScreen(type: LegalDocumentType.privacyPolicy),
  ),
  GoRoute(
    path: AppRoutes.termsOfService,
    builder: (context, state) =>
        const LegalDocumentScreen(type: LegalDocumentType.termsOfService),
  ),
  GoRoute(
    path: AppRoutes.communityGuidelines,
    builder: (context, state) =>
        const LegalDocumentScreen(type: LegalDocumentType.communityGuidelines),
  ),

  // Two-Factor Authentication routes
  GoRoute(
    path: AppRoutes.twoFactorSetup,
    builder: (context, state) => const TwoFactorSetupScreen(),
  ),
  GoRoute(
    path: AppRoutes.twoFactorVerify,
    builder: (context, state) {
      final factorId = state.uri.queryParameters['factorId'];
      if (factorId == null || factorId.isEmpty) {
        return const NotFoundScreen();
      }
      return TwoFactorVerifyScreen(factorId: factorId);
    },
  ),

  // Health Records routes
  GoRoute(
    path: AppRoutes.healthRecords,
    builder: (context, state) => const HealthRecordListScreen(),
    routes: [
      GoRoute(
        path: 'form',
        builder: (context, state) => HealthRecordFormScreen(
          editRecordId: state.uri.queryParameters['editId'],
          preselectedBirdId: state.uri.queryParameters['birdId'],
        ),
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) =>
            HealthRecordDetailScreen(recordId: state.pathParameters['id']!),
      ),
    ],
  ),
];
