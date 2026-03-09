import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/environment_monitor.dart';

/// Provides the singleton [EnvironmentMonitor].
final environmentMonitorProvider = Provider<EnvironmentMonitor>((ref) {
  return EnvironmentMonitor();
});

/// Notifier for the latest environment reading.
class LatestReadingNotifier extends Notifier<EnvironmentReading?> {
  @override
  EnvironmentReading? build() => null;
}

/// Stores the latest environment reading.
///
/// UI can update this via the notifier when the user manually inputs
/// or when a Bluetooth sensor provides data.
final latestReadingProvider =
    NotifierProvider<LatestReadingNotifier, EnvironmentReading?>(LatestReadingNotifier.new);
