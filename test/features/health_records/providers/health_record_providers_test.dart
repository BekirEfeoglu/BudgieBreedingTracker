import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

HealthRecord _record({
  required String id,
  required HealthRecordType type,
  String title = 'Checkup',
  String? description,
  String? veterinarian,
}) {
  return HealthRecord(
    id: id,
    userId: 'user-1',
    date: DateTime(2024, 1, 15),
    type: type,
    title: title,
    description: description,
    veterinarian: veterinarian,
  );
}

void main() {
  group('HealthRecordFilter.recordType', () {
    test('all filter has null recordType', () {
      expect(HealthRecordFilter.all.recordType, isNull);
    });

    test('checkup maps to HealthRecordType.checkup', () {
      expect(HealthRecordFilter.checkup.recordType, HealthRecordType.checkup);
    });

    test('illness maps to HealthRecordType.illness', () {
      expect(HealthRecordFilter.illness.recordType, HealthRecordType.illness);
    });

    test('injury maps to HealthRecordType.injury', () {
      expect(HealthRecordFilter.injury.recordType, HealthRecordType.injury);
    });

    test('vaccination maps to HealthRecordType.vaccination', () {
      expect(
        HealthRecordFilter.vaccination.recordType,
        HealthRecordType.vaccination,
      );
    });

    test('medication maps to HealthRecordType.medication', () {
      expect(
        HealthRecordFilter.medication.recordType,
        HealthRecordType.medication,
      );
    });

    test('death maps to HealthRecordType.death', () {
      expect(HealthRecordFilter.death.recordType, HealthRecordType.death);
    });
  });

  group('HealthRecordFilterNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default filter is all', () {
      expect(
        container.read(healthRecordFilterProvider),
        HealthRecordFilter.all,
      );
    });

    test('can change to checkup filter', () {
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.checkup;
      expect(
        container.read(healthRecordFilterProvider),
        HealthRecordFilter.checkup,
      );
    });

    test('can change to illness filter', () {
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.illness;
      expect(
        container.read(healthRecordFilterProvider),
        HealthRecordFilter.illness,
      );
    });
  });

  group('HealthRecordSearchQueryNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default query is empty string', () {
      expect(container.read(healthRecordSearchQueryProvider), '');
    });

    test('can update search query', () {
      container.read(healthRecordSearchQueryProvider.notifier).state = 'flu';
      expect(container.read(healthRecordSearchQueryProvider), 'flu');
    });
  });

  group('filteredHealthRecordsProvider', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('all filter returns all records', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup),
        _record(id: '2', type: HealthRecordType.illness),
        _record(id: '3', type: HealthRecordType.vaccination),
      ];

      final filtered = container.read(filteredHealthRecordsProvider(records));
      expect(filtered, hasLength(3));
    });

    test('checkup filter returns only checkup records', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup),
        _record(id: '2', type: HealthRecordType.illness),
        _record(id: '3', type: HealthRecordType.checkup),
      ];
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.checkup;

      final filtered = container.read(filteredHealthRecordsProvider(records));
      expect(filtered, hasLength(2));
      expect(filtered.every((r) => r.type == HealthRecordType.checkup), isTrue);
    });

    test('illness filter excludes non-illness records', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup),
        _record(id: '2', type: HealthRecordType.illness),
      ];
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.illness;

      final filtered = container.read(filteredHealthRecordsProvider(records));
      expect(filtered, hasLength(1));
      expect(filtered.first.id, '2');
    });

    test('empty records returns empty list regardless of filter', () {
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.vaccination;
      final filtered = container.read(filteredHealthRecordsProvider([]));
      expect(filtered, isEmpty);
    });
  });

  group('searchedAndFilteredHealthRecordsProvider', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('empty query returns all records', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup, title: 'Flu shot'),
        _record(id: '2', type: HealthRecordType.illness, title: 'Cold'),
      ];

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      expect(result, hasLength(2));
    });

    test('searches by title (case-insensitive)', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup, title: 'Flu shot'),
        _record(
          id: '2',
          type: HealthRecordType.illness,
          title: 'Cold treatment',
        ),
      ];
      container.read(healthRecordSearchQueryProvider.notifier).state = 'FLU';

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('searches by description', () {
      final records = [
        _record(
          id: '1',
          type: HealthRecordType.checkup,
          title: 'Visit',
          description: 'Wing injury noticed',
        ),
        _record(id: '2', type: HealthRecordType.illness, title: 'Flu'),
      ];
      container.read(healthRecordSearchQueryProvider.notifier).state = 'wing';

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('searches by veterinarian name', () {
      final records = [
        _record(
          id: '1',
          type: HealthRecordType.checkup,
          title: 'Visit',
          veterinarian: 'Dr. Smith',
        ),
        _record(id: '2', type: HealthRecordType.illness, title: 'Flu'),
      ];
      container.read(healthRecordSearchQueryProvider.notifier).state = 'smith';

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });

    test('returns empty list when no records match query', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup, title: 'Flu shot'),
      ];
      container.read(healthRecordSearchQueryProvider.notifier).state =
          'nonexistent';

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      expect(result, isEmpty);
    });

    test('filter and search work together', () {
      final records = [
        _record(id: '1', type: HealthRecordType.checkup, title: 'Flu shot'),
        _record(id: '2', type: HealthRecordType.checkup, title: 'Annual'),
        _record(id: '3', type: HealthRecordType.illness, title: 'Flu illness'),
      ];
      container.read(healthRecordFilterProvider.notifier).state =
          HealthRecordFilter.checkup;
      container.read(healthRecordSearchQueryProvider.notifier).state = 'flu';

      final result = container.read(
        searchedAndFilteredHealthRecordsProvider(records),
      );
      // Filter: checkup only (1, 2) → search 'flu': only 1
      expect(result, hasLength(1));
      expect(result.first.id, '1');
    });
  });
}
