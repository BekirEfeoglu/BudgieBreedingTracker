import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/home_widget_dashboard_snapshot.dart';

HomeWidgetDashboardSnapshot _snapshot({
  int eggTurningCount = 2,
  int activeBreedingsCount = 1,
  String nextTurningLabel = '10:00',
  String lastUpdatedLabel = 'just now',
  DateTime? lastUpdatedAt,
}) => HomeWidgetDashboardSnapshot(
  eggTurningCount: eggTurningCount,
  activeBreedingsCount: activeBreedingsCount,
  nextTurningLabel: nextTurningLabel,
  lastUpdatedLabel: lastUpdatedLabel,
  lastUpdatedAt: lastUpdatedAt ?? DateTime(2026, 1, 1, 10, 0),
);

void main() {
  group('HomeWidgetDashboardSnapshot equality', () {
    test(
      'two snapshots with identical content but different lastUpdatedAt/'
      'lastUpdatedLabel are equal — this is what keeps the home-widget '
      'sync dedup guard effective across recomputes',
      () {
        final a = _snapshot(
          lastUpdatedAt: DateTime(2026, 1, 1, 10, 0, 0),
          lastUpdatedLabel: 'just now',
        );
        final b = _snapshot(
          lastUpdatedAt: DateTime(2026, 1, 1, 10, 0, 5),
          lastUpdatedLabel: '5 seconds ago',
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      },
    );

    test('snapshots differ when eggTurningCount differs', () {
      expect(
        _snapshot(eggTurningCount: 2),
        isNot(equals(_snapshot(eggTurningCount: 3))),
      );
    });

    test('snapshots differ when activeBreedingsCount differs', () {
      expect(
        _snapshot(activeBreedingsCount: 1),
        isNot(equals(_snapshot(activeBreedingsCount: 2))),
      );
    });

    test('snapshots differ when nextTurningLabel differs', () {
      expect(
        _snapshot(nextTurningLabel: '10:00'),
        isNot(equals(_snapshot(nextTurningLabel: '14:00'))),
      );
    });
  });
}
