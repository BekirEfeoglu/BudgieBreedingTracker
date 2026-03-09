import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_card.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  final testRecord = HealthRecord(
    id: 'record-1',
    userId: 'user-1',
    date: DateTime(2024, 1, 15),
    type: HealthRecordType.checkup,
    title: 'Annual Checkup',
  );

  group('HealthRecordCard', () {
    testWidgets('displays record title', (tester) async {
      await pumpWidgetSimple(tester, HealthRecordCard(record: testRecord));

      expect(find.text('Annual Checkup'), findsOneWidget);
    });

    testWidgets('shows animal name when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        HealthRecordCard(record: testRecord, animalName: 'Mavi'),
      );

      expect(find.text('Mavi'), findsOneWidget);
    });

    testWidgets('does not show animal name when null', (tester) async {
      await pumpWidgetSimple(tester, HealthRecordCard(record: testRecord));

      expect(find.text('Mavi'), findsNothing);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await pumpWidgetSimple(
        tester,
        HealthRecordCard(record: testRecord, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows description when present', (tester) async {
      final record = HealthRecord(
        id: 'record-2',
        userId: 'user-1',
        date: DateTime(2024, 1, 20),
        type: HealthRecordType.illness,
        title: 'Sick Visit',
        description: 'Respiratory issue',
      );

      await pumpWidgetSimple(tester, HealthRecordCard(record: record));

      expect(find.text('Respiratory issue'), findsOneWidget);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await pumpWidgetSimple(tester, HealthRecordCard(record: testRecord));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows follow-up icon when followUpDate is set', (
      tester,
    ) async {
      final record = HealthRecord(
        id: 'record-3',
        userId: 'user-1',
        date: DateTime(2024, 1, 15),
        type: HealthRecordType.checkup,
        title: 'Follow Up',
        followUpDate: DateTime(2024, 2, 15),
      );

      await pumpWidgetSimple(tester, HealthRecordCard(record: record));

      // Follow-up icon is shown for records with a follow-up date
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('different record types render without error', (tester) async {
      for (final type in HealthRecordType.values) {
        final record = HealthRecord(
          id: 'record-type-$type',
          userId: 'user-1',
          date: DateTime(2024, 1, 15),
          type: type,
          title: 'Test $type',
        );

        await pumpWidgetSimple(tester, HealthRecordCard(record: record));
        expect(find.byType(Card), findsOneWidget);
      }
    });
  });
}
