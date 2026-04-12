import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/logger.dart';

/// Tracks user interaction and triggers a callback after a period of
/// inactivity. Wrap the app's root widget with [wrapWithListener] to
/// intercept pointer events without affecting the widget tree.
///
/// Also monitors app lifecycle: when the app goes to background, the
/// elapsed background time is checked on resume. If it exceeds the
/// timeout, [onTimeout] fires immediately.
///
/// Typical usage:
/// ```dart
/// final guard = InactivityGuard(
///   timeout: Duration(minutes: 30),
///   onTimeout: () => ref.read(authActionsProvider).signOut(),
/// );
/// guard.start();
/// // In build(): guard.wrapWithListener(child: materialApp)
/// ```
class InactivityGuard with WidgetsBindingObserver {
  final Duration timeout;
  final VoidCallback onTimeout;

  /// Injectable clock for testing. Returns [DateTime.now] by default.
  final DateTime Function() clock;

  Timer? _timer;
  bool _isRunning = false;
  bool _isDisposed = false;
  DateTime? _lastActivity;
  DateTime? _backgroundedAt;

  static const _tag = '[InactivityGuard]';

  InactivityGuard({
    this.timeout = const Duration(minutes: 30),
    required this.onTimeout,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  /// Starts or restarts the inactivity timer and registers lifecycle observer.
  void start() {
    if (_isDisposed) return;
    _isRunning = true;
    _resetTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops the inactivity timer and removes lifecycle observer.
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _backgroundedAt = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Records user activity and resets the timer.
  ///
  /// Throttled to at most once per second to avoid excessive timer resets
  /// from rapid pointer events (scrolling, dragging).
  void recordActivity() {
    if (!_isRunning) return;
    final now = clock();
    if (_lastActivity != null && now.difference(_lastActivity!).inSeconds < 1) {
      return;
    }
    _lastActivity = now;
    _resetTimer();
  }

  /// Wraps [child] with a [Listener] that detects pointer events
  /// (taps, scrolls, drags) without consuming them.
  Widget wrapWithListener({required Widget child}) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => recordActivity(),
      onPointerMove: (_) => recordActivity(),
      child: child,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning || _isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // App going to background — record timestamp and stop timer
      _backgroundedAt = clock();
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed) {
      // App returning to foreground — check if timeout elapsed during background
      if (_backgroundedAt != null) {
        final elapsed = clock().difference(_backgroundedAt!);
        _backgroundedAt = null;
        if (elapsed >= timeout) {
          AppLogger.info(
            '$_tag Session timed out during background '
            '(${elapsed.inMinutes} minutes)',
          );
          _isRunning = false;
          onTimeout();
          return;
        }
        // Still within timeout — restart timer with remaining time only
        final remaining = timeout - elapsed;
        _timer?.cancel();
        _timer = Timer(remaining, _handleTimeout);
        return;
      }
      _resetTimer();
    }
  }

  void dispose() {
    _isDisposed = true;
    stop();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(timeout, _handleTimeout);
  }

  void _handleTimeout() {
    if (!_isRunning || _isDisposed) return;
    AppLogger.info('$_tag Session timed out after ${timeout.inMinutes} minutes');
    _isRunning = false;
    onTimeout();
  }
}
