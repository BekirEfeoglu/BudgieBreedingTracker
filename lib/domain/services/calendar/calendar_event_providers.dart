import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';

/// Provides the [CalendarEventGenerator] for auto-creating calendar
/// events from breeding, egg, and chick milestones.
final calendarEventGeneratorProvider = Provider<CalendarEventGenerator>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  return CalendarEventGenerator(eventRepo);
});
