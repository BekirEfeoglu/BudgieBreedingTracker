import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/supabase_error_utils.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/egg_species_resolver.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/notification_settings_shared_providers.dart';
import 'package:uuid/uuid.dart';

part 'chick_form_notifier.dart';
part 'chick_form_status_actions.dart';

/// State for the chick form.
class ChickFormState {
  final bool isLoading;
  final String? error;
  final String? warning;
  final bool isSuccess;

  const ChickFormState({
    this.isLoading = false,
    this.error,
    this.warning,
    this.isSuccess = false,
  });

  ChickFormState copyWith({
    bool? isLoading,
    String? error,
    String? warning,
    bool? isSuccess,
  }) {
    return ChickFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      warning: warning,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Form state and actions for creating/editing chicks.
final chickFormStateProvider =
    NotifierProvider<ChickFormNotifier, ChickFormState>(ChickFormNotifier.new);
