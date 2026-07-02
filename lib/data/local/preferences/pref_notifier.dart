import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';

/// Base for settings notifiers whose value is persisted in SharedPreferences.
///
/// [build] returns [defaultValue] synchronously and starts a fire-and-forget
/// load. The base class guards the shared lifecycle hazards of that pattern:
/// a value loaded from disk never overwrites a change the user made while the
/// load was in flight, nothing is written to state after the provider is
/// disposed, and storage failures are logged instead of escaping as unhandled
/// async errors.
abstract class PrefNotifier<T> extends Notifier<T> {
  bool _disposed = false;
  bool _userModified = false;

  /// Value returned synchronously from [build] until the load completes.
  T get defaultValue;

  /// Reads the persisted value; null when nothing valid is stored.
  Future<T?> readFromPrefs(SharedPreferences prefs);

  /// Persists [value].
  Future<void> writeToPrefs(SharedPreferences prefs, T value);

  /// Reacts to the effective value (initial load and every [set] call).
  void onValue(T value) {}

  @override
  T build() {
    _disposed = false;
    _userModified = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_loadFromPrefs());
    return defaultValue;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = await readFromPrefs(prefs);
      // A change made while the load was in flight wins over the disk value.
      if (_disposed || _userModified || value == null) return;
      state = value;
      onValue(value);
    } catch (e, st) {
      AppLogger.error('$runtimeType load failed', e, st);
    }
  }

  /// Sets [value], notifies [onValue], and persists it.
  Future<void> set(T value) async {
    _userModified = true;
    state = value;
    onValue(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await writeToPrefs(prefs, value);
    } catch (e, st) {
      AppLogger.error('$runtimeType persist failed', e, st);
    }
  }
}

/// A [PrefNotifier] for bool toggles stored under a single preference key.
abstract class PrefBoolNotifier extends PrefNotifier<bool> {
  PrefBoolNotifier(this.prefKey, {required bool defaultValue})
    : _default = defaultValue;

  final String prefKey;
  final bool _default;

  @override
  bool get defaultValue => _default;

  @override
  Future<bool?> readFromPrefs(SharedPreferences prefs) async =>
      prefs.getBool(prefKey);

  @override
  Future<void> writeToPrefs(SharedPreferences prefs, bool value) =>
      prefs.setBool(prefKey, value);

  Future<void> toggle() => set(!state);
}
