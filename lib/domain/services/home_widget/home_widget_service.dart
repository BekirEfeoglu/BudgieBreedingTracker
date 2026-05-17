import 'package:home_widget/home_widget.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/home_widget_dashboard_snapshot.dart';

abstract final class AppHomeWidgetConstants {
  static const appGroupId = 'group.com.budgiebreeding.tracker';
  static const iOSWidgetName = 'BudgieDashboardWidget';
  static const androidWidgetName = 'BudgieDashboardWidgetReceiver';
  static const qualifiedAndroidWidgetName =
      'com.budgiebreeding.budgie_breeding_tracker.widget.'
      'BudgieDashboardWidgetReceiver';

  static const eggTurningCountKey = 'egg_turning_count';
  static const activeBreedingsCountKey = 'active_breedings_count';
  static const nextTurningLabelKey = 'next_turning_label';
  static const hasWorkTodayKey = 'has_work_today';
  static const lastUpdatedLabelKey = 'last_updated_label';
  static const lastUpdatedEpochSecondsKey = 'last_updated_epoch_seconds';
}

abstract interface class HomeWidgetGateway {
  Future<void> setAppGroupId(String groupId);

  Future<void> saveString(String key, String value);

  Future<void> saveInt(String key, int value);

  Future<void> saveBool(String key, bool value);

  Future<void> updateWidget({
    required String iOSName,
    required String androidName,
    required String qualifiedAndroidName,
  });
}

class PluginHomeWidgetGateway implements HomeWidgetGateway {
  const PluginHomeWidgetGateway();

  @override
  Future<void> setAppGroupId(String groupId) =>
      HomeWidget.setAppGroupId(groupId);

  @override
  Future<void> saveString(String key, String value) =>
      HomeWidget.saveWidgetData<String>(key, value);

  @override
  Future<void> saveInt(String key, int value) =>
      HomeWidget.saveWidgetData<int>(key, value);

  @override
  Future<void> saveBool(String key, bool value) =>
      HomeWidget.saveWidgetData<bool>(key, value);

  @override
  Future<void> updateWidget({
    required String iOSName,
    required String androidName,
    required String qualifiedAndroidName,
  }) => HomeWidget.updateWidget(
    iOSName: iOSName,
    androidName: androidName,
    qualifiedAndroidName: qualifiedAndroidName,
  );
}

class HomeWidgetService {
  final HomeWidgetGateway _gateway;

  const HomeWidgetService({HomeWidgetGateway? gateway})
    : _gateway = gateway ?? const PluginHomeWidgetGateway();

  Future<void> syncDashboardSnapshot(
    HomeWidgetDashboardSnapshot snapshot,
  ) async {
    try {
      await _gateway.setAppGroupId(AppHomeWidgetConstants.appGroupId);
      await _gateway.saveInt(
        AppHomeWidgetConstants.eggTurningCountKey,
        snapshot.eggTurningCount,
      );
      await _gateway.saveInt(
        AppHomeWidgetConstants.activeBreedingsCountKey,
        snapshot.activeBreedingsCount,
      );
      await _gateway.saveString(
        AppHomeWidgetConstants.nextTurningLabelKey,
        snapshot.nextTurningLabel,
      );
      await _gateway.saveBool(
        AppHomeWidgetConstants.hasWorkTodayKey,
        snapshot.hasWorkToday,
      );
      await _gateway.saveString(
        AppHomeWidgetConstants.lastUpdatedLabelKey,
        snapshot.lastUpdatedLabel,
      );
      await _gateway.saveInt(
        AppHomeWidgetConstants.lastUpdatedEpochSecondsKey,
        snapshot.lastUpdatedEpochSeconds,
      );
      await _gateway.updateWidget(
        iOSName: AppHomeWidgetConstants.iOSWidgetName,
        androidName: AppHomeWidgetConstants.androidWidgetName,
        qualifiedAndroidName: AppHomeWidgetConstants.qualifiedAndroidWidgetName,
      );
    } catch (e, st) {
      AppLogger.error(
        '[HomeWidgetService] Dashboard widget sync failed: $e',
        e,
        st,
      );
    }
  }
}
