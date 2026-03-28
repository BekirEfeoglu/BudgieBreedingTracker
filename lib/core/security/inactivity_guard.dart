import 'dart:async';

import 'package:flutter/widgets.dart';

import '../utils/logger.dart';

/// Tracks user interaction and triggers a callback after a period of
/// inactivity. Wrap the app's root widget with [wrapWithListener] to
/// intercept pointer events without affecting the widget tree.
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
class InactivityGuard {
  final Duration timeout;
  final VoidCallback onTimeout;

  Timer? _timer;
  bool _isRunning = false;
  bool _isDisposed = false;
  DateTime? _lastActivity;

  static const _tag = '[InactivityGuard]';

  InactivityGuard({
    this.timeout = const Duration(minutes: 30),
    required this.onTimeout,
  });

  /// Starts or restarts the inactivity timer.
  void start() {
    if (_isDisposed) return;
    _isRunning = true;
    _resetTimer();
  }

  /// Stops the inactivity timer.
  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Records user activity and resets the timer.
  ///
  /// Throttled to at most once per second to avoid excessive timer resets
  /// from rapid pointer events (scrolling, dragging).
  void recordActivity() {
    if (!_isRunning) return;
    final now = DateTime.now();
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
