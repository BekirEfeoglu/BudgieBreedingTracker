import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

// Enums

enum FeedbackCategory {
  bug,
  feature,
  general;

  String get label => switch (this) {
    FeedbackCategory.bug => 'feedback.bug'.tr(),
    FeedbackCategory.feature => 'feedback.feature_request'.tr(),
    FeedbackCategory.general => 'feedback.general'.tr(),
  };

  String get description => switch (this) {
    FeedbackCategory.bug => 'feedback.bug_description'.tr(),
    FeedbackCategory.feature => 'feedback.feature_description'.tr(),
    FeedbackCategory.general => 'feedback.general_description'.tr(),
  };

  IconData get icon => switch (this) {
    FeedbackCategory.bug => LucideIcons.bug,
    FeedbackCategory.feature => LucideIcons.lightbulb,
    FeedbackCategory.general => LucideIcons.messageCircle,
  };

  Color get color => switch (this) {
    FeedbackCategory.bug => AppColors.error,
    FeedbackCategory.feature => AppColors.warning,
    FeedbackCategory.general => AppColors.budgieBlue,
  };

  String get value => switch (this) {
    FeedbackCategory.bug => 'bug',
    FeedbackCategory.feature => 'feature',
    FeedbackCategory.general => 'general',
  };

  static FeedbackCategory fromString(String value) => switch (value) {
    'bug' => FeedbackCategory.bug,
    'feature' => FeedbackCategory.feature,
    _ => FeedbackCategory.general,
  };
}

enum FeedbackStatus {
  open,
  inProgress,
  resolved,
  closed,
  unknown;

  factory FeedbackStatus.fromString(String value) => switch (value) {
    'open' => FeedbackStatus.open,
    'in_progress' => FeedbackStatus.inProgress,
    'resolved' => FeedbackStatus.resolved,
    'closed' => FeedbackStatus.closed,
    _ => FeedbackStatus.unknown,
  };

  String get label => switch (this) {
    FeedbackStatus.open => 'feedback.status_open'.tr(),
    FeedbackStatus.inProgress => 'feedback.status_in_progress'.tr(),
    FeedbackStatus.resolved => 'feedback.status_resolved'.tr(),
    FeedbackStatus.closed => 'feedback.status_closed'.tr(),
    FeedbackStatus.unknown => 'feedback.status_unknown'.tr(),
  };

  Color get color => switch (this) {
    FeedbackStatus.open => AppColors.budgieBlue,
    FeedbackStatus.inProgress => AppColors.warning,
    FeedbackStatus.resolved => AppColors.success,
    FeedbackStatus.closed => AppColors.neutral400,
    FeedbackStatus.unknown => AppColors.neutral400,
  };

  IconData get icon => switch (this) {
    FeedbackStatus.open => LucideIcons.circle,
    FeedbackStatus.inProgress => LucideIcons.clock,
    FeedbackStatus.resolved => LucideIcons.checkCircle2,
    FeedbackStatus.closed => LucideIcons.xCircle,
    FeedbackStatus.unknown => LucideIcons.helpCircle,
  };
}

// Data class

class FeedbackEntry {
  final String id;
  final FeedbackCategory category;
  final String subject;
  final String message;
  final FeedbackStatus status;
  final String? email;
  final String? adminResponse;
  final DateTime? createdAt;

  const FeedbackEntry({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    this.email,
    this.adminResponse,
    this.createdAt,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json[SupabaseConstants.feedbackColId] as String,
      category: FeedbackCategory.fromString(
        json[SupabaseConstants.feedbackColType] as String? ?? 'general',
      ),
      subject: json[SupabaseConstants.feedbackColSubject] as String? ?? '',
      message: json[SupabaseConstants.feedbackColMessage] as String? ?? '',
      status: FeedbackStatus.fromString(
        json[SupabaseConstants.feedbackColStatus] as String? ?? 'open',
      ),
      email: json[SupabaseConstants.feedbackColEmail] as String?,
      adminResponse:
          json[SupabaseConstants.feedbackColAdminResponse] as String?,
      createdAt: json[SupabaseConstants.feedbackColCreatedAt] != null
          ? DateTime.tryParse(
              json[SupabaseConstants.feedbackColCreatedAt] as String,
            )
          : null,
    );
  }
}

// Providers

/// Fetches the user's feedback history from Supabase via [FeedbackRemoteSource].
final feedbackHistoryProvider =
    FutureProvider.family<List<FeedbackEntry>, String>((ref, userId) async {
      final initialized = ref.watch(supabaseInitializedProvider);
      if (!initialized) return [];

      final remoteSource = ref.watch(feedbackRemoteSourceProvider);
      final response = await remoteSource.fetchByUser(userId);

      return response.map((json) => FeedbackEntry.fromJson(json)).toList();
    });

// Form state

/// State for the feedback form.
class FeedbackFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const FeedbackFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  FeedbackFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return FeedbackFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier that handles feedback submission to Supabase.
class FeedbackFormNotifier extends Notifier<FeedbackFormState> {
  @override
  FeedbackFormState build() => const FeedbackFormState();

  /// Submits feedback via [FeedbackRemoteSource].
  Future<void> submit({
    required FeedbackCategory category,
    required String subject,
    required String message,
    String? email,
    String? appVersion,
    String? deviceInfo,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final remoteSource = ref.read(feedbackRemoteSourceProvider);
      final userId = ref.read(currentUserIdProvider);

      final feedbackId = const Uuid().v4();

      await remoteSource.insert({
        SupabaseConstants.feedbackColId: feedbackId,
        SupabaseConstants.feedbackColUserId: userId,
        SupabaseConstants.feedbackColType: category.value,
        SupabaseConstants.feedbackColSubject: subject,
        SupabaseConstants.feedbackColMessage: message,
        if (email != null && email.isNotEmpty)
          SupabaseConstants.feedbackColEmail: email,
        if (appVersion != null)
          SupabaseConstants.feedbackColAppVersion: appVersion,
        SupabaseConstants.feedbackColPlatform: deviceInfo,
        SupabaseConstants.feedbackColStatus: 'open',
      });

      // Notify founders about the new feedback
      await _notifyFounders(
        remoteSource: remoteSource,
        feedbackId: feedbackId,
        category: category,
        subject: subject,
      );

      // Refresh history so newly submitted feedback appears immediately
      ref.invalidate(feedbackHistoryProvider);

      AppHaptics.lightImpact();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('FeedbackFormNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sends a notification to all founder-role admins about new feedback.
  Future<void> _notifyFounders({
    required FeedbackRemoteSource remoteSource,
    required String feedbackId,
    required FeedbackCategory category,
    required String subject,
  }) async {
    try {
      final founderIds = await remoteSource.fetchFounderIds();
      if (founderIds.isEmpty) return;

      final now = DateTime.now().toIso8601String();
      final notifications = <Map<String, dynamic>>[];

      for (final founderId in founderIds) {
        notifications.add({
          SupabaseConstants.notificationColId: const Uuid().v4(),
          SupabaseConstants.notificationColUserId: founderId,
          SupabaseConstants.notificationColTitle:
              'feedback.notify_founder_title'.tr(args: [category.label]),
          SupabaseConstants.notificationColBody: subject,
          SupabaseConstants.notificationColType: 'custom',
          SupabaseConstants.notificationColPriority: 'normal',
          SupabaseConstants.notificationColRead: false,
          SupabaseConstants.notificationColReferenceId: feedbackId,
          SupabaseConstants.notificationColReferenceType: 'feedback',
          SupabaseConstants.notificationColCreatedAt: now,
          SupabaseConstants.notificationColUpdatedAt: now,
        });
      }

      await remoteSource.notifyFounders(notifications);
    } catch (e, st) {
      AppLogger.warning('FeedbackFormNotifier: Failed to notify founders: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Resets the form state.
  void reset() => state = const FeedbackFormState();
}

/// Provider for feedback form state and actions.
final feedbackFormStateProvider =
    NotifierProvider<FeedbackFormNotifier, FeedbackFormState>(
      FeedbackFormNotifier.new,
    );
