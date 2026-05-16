import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/home_widget/home_widget_service.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';

class _FakeHomeWidgetGateway implements HomeWidgetGateway {
  final List<String> calls = [];
  final Map<String, Object> values = {};

  @override
  Future<void> setAppGroupId(String groupId) async {
    calls.add('setAppGroupId:$groupId');
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> saveInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<void> saveString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> updateWidget({
    required String iOSName,
    required String androidName,
    required String qualifiedAndroidName,
  }) async {
    calls.add('updateWidget:$iOSName:$androidName:$qualifiedAndroidName');
  }
}

void main() {
  test(
    'syncDashboardSnapshot writes values and requests native update',
    () async {
      final gateway = _FakeHomeWidgetGateway();
      final service = HomeWidgetService(gateway: gateway);

      final lastUpdatedAt = DateTime.utc(2026, 5, 17, 9, 5);
      await service.syncDashboardSnapshot(
        HomeWidgetDashboardSnapshot(
          eggTurningCount: 3,
          activeBreedingsCount: 2,
          nextTurningLabel: '14:30',
          lastUpdatedLabel: '09:05',
          lastUpdatedAt: lastUpdatedAt,
        ),
      );

      expect(gateway.values[AppHomeWidgetConstants.eggTurningCountKey], 3);
      expect(gateway.values[AppHomeWidgetConstants.activeBreedingsCountKey], 2);
      expect(
        gateway.values[AppHomeWidgetConstants.nextTurningLabelKey],
        '14:30',
      );
      expect(gateway.values[AppHomeWidgetConstants.hasWorkTodayKey], isTrue);
      expect(
        gateway.values[AppHomeWidgetConstants.lastUpdatedLabelKey],
        '09:05',
      );
      expect(
        gateway.values[AppHomeWidgetConstants.lastUpdatedEpochSecondsKey],
        lastUpdatedAt.millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        gateway.calls,
        contains('setAppGroupId:${AppHomeWidgetConstants.appGroupId}'),
      );
      expect(
        gateway.calls,
        contains(
          'updateWidget:${AppHomeWidgetConstants.iOSWidgetName}:'
          '${AppHomeWidgetConstants.androidWidgetName}:'
          '${AppHomeWidgetConstants.qualifiedAndroidWidgetName}',
        ),
      );
    },
  );
}
