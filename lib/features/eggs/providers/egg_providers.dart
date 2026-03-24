import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/supabase_error_utils.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:uuid/uuid.dart';

part 'egg_actions_notifier.dart';

/// All eggs for a user (live stream).
///
/// Single source of truth - imported by home, breeding, and statistics.
final eggsStreamProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchAll(userId);
});

/// Eggs for a specific incubation (live stream).
final eggsForIncubationProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  incubationId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchByIncubation(incubationId);
});

/// Actions notifier for egg CRUD operations.
final eggActionsProvider =
    NotifierProvider<EggActionsNotifier, EggActionsState>(
      EggActionsNotifier.new,
    );
