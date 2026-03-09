import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

Event _dummyEvent() => Event(
  id: 'id',
  title: 'title',
  eventDate: DateTime(2026, 1, 1),
  type: EventType.custom,
  userId: 'user-1',
);

void main() {
  late MockEventRepository mockEventRepo;

  setUpAll(() {
    registerFallbackValue(_dummyEvent());
  });

  setUp(() {
    mockEventRepo = MockEventRepository();
    when(() => mockEventRepo.save(any())).thenAnswer((_) async {});
  });

  test(
    'calendarEventGeneratorProvider wires generator with event repository',
    () async {
      final container = ProviderContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockEventRepo)],
      );
      addTearDown(container.dispose);

      final generator = container.read(calendarEventGeneratorProvider);

      await generator.generateEggEvents(
        userId: 'user-1',
        layDate: DateTime.now().add(const Duration(days: 1)),
        eggNumber: 1,
        incubationId: 'inc-1',
      );

      verify(() => mockEventRepo.save(any())).called(2);
    },
  );
}
