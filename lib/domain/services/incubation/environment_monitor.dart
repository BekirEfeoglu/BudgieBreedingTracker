import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Alert severity levels for environment readings.
enum IncubationAlertSeverity {
  /// Reading is within optimal range.
  normal,

  /// Reading is within acceptable range but not optimal.
  warning,

  /// Reading is outside acceptable range.
  critical,
}

/// A snapshot of environment conditions with alert status.
class EnvironmentReading {
  final double temperature;
  final double humidity;
  final IncubationAlertSeverity temperatureAlert;
  final IncubationAlertSeverity humidityAlert;
  final DateTime timestamp;

  const EnvironmentReading({
    required this.temperature,
    required this.humidity,
    required this.temperatureAlert,
    required this.humidityAlert,
    required this.timestamp,
  });

  /// Whether any reading is in critical state.
  bool get hasCriticalAlert =>
      temperatureAlert == IncubationAlertSeverity.critical ||
      humidityAlert == IncubationAlertSeverity.critical;

  /// Whether any reading is in warning or critical state.
  bool get hasAlert =>
      temperatureAlert != IncubationAlertSeverity.normal ||
      humidityAlert != IncubationAlertSeverity.normal;
}

/// Monitors temperature and humidity for incubation environments.
///
/// Evaluates readings against [IncubationConstants] thresholds and
/// generates alerts when values fall outside acceptable ranges.
///
/// Temperature optimal: 37.5 C (range: 37.0 - 38.0)
/// Humidity optimal: 60% (range: 55% - 65%)
class EnvironmentMonitor {
  /// Tolerance margin outside the min/max range before critical alert.
  static const double _tempCriticalMargin = 0.5;
  static const double _humidityCriticalMargin = 5.0;

  /// Evaluates a temperature and humidity reading.
  EnvironmentReading evaluate({
    required double temperature,
    required double humidity,
  }) {
    final tempAlert = _evaluateTemperature(temperature);
    final humidityAlert = _evaluateHumidity(humidity);

    final reading = EnvironmentReading(
      temperature: temperature,
      humidity: humidity,
      temperatureAlert: tempAlert,
      humidityAlert: humidityAlert,
      timestamp: DateTime.now(),
    );

    if (reading.hasCriticalAlert) {
      AppLogger.warning(
        '[EnvironmentMonitor] Critical: '
        'temp=${temperature}C (${tempAlert.name}), '
        'humidity=$humidity% (${humidityAlert.name})',
      );
    }

    return reading;
  }

  /// Returns a human-readable recommendation for current conditions.
  String getRecommendation(EnvironmentReading reading) {
    final messages = <String>[];

    if (reading.temperature < IncubationConstants.temperatureMin) {
      messages.add(
        'environment.temp_too_low'.tr(
          args: [
            reading.temperature.toString(),
            IncubationConstants.temperatureMin.toString(),
            IncubationConstants.temperatureMax.toString(),
          ],
        ),
      );
    } else if (reading.temperature > IncubationConstants.temperatureMax) {
      messages.add(
        'environment.temp_too_high'.tr(
          args: [
            reading.temperature.toString(),
            IncubationConstants.temperatureMin.toString(),
            IncubationConstants.temperatureMax.toString(),
          ],
        ),
      );
    }

    if (reading.humidity < IncubationConstants.humidityMin) {
      messages.add(
        'environment.humidity_too_low'.tr(
          args: [
            reading.humidity.toString(),
            IncubationConstants.humidityMin.toString(),
            IncubationConstants.humidityMax.toString(),
          ],
        ),
      );
    } else if (reading.humidity > IncubationConstants.humidityMax) {
      messages.add(
        'environment.humidity_too_high'.tr(
          args: [
            reading.humidity.toString(),
            IncubationConstants.humidityMin.toString(),
            IncubationConstants.humidityMax.toString(),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return 'environment.conditions_ideal'.tr();
    }

    return messages.join(' ');
  }

  IncubationAlertSeverity _evaluateTemperature(double temp) {
    if (temp >= IncubationConstants.temperatureMin &&
        temp <= IncubationConstants.temperatureMax) {
      return IncubationAlertSeverity.normal;
    }

    if (temp < IncubationConstants.temperatureMin - _tempCriticalMargin ||
        temp > IncubationConstants.temperatureMax + _tempCriticalMargin) {
      return IncubationAlertSeverity.critical;
    }

    return IncubationAlertSeverity.warning;
  }

  IncubationAlertSeverity _evaluateHumidity(double humidity) {
    if (humidity >= IncubationConstants.humidityMin &&
        humidity <= IncubationConstants.humidityMax) {
      return IncubationAlertSeverity.normal;
    }

    if (humidity < IncubationConstants.humidityMin - _humidityCriticalMargin ||
        humidity > IncubationConstants.humidityMax + _humidityCriticalMargin) {
      return IncubationAlertSeverity.critical;
    }

    return IncubationAlertSeverity.warning;
  }
}
