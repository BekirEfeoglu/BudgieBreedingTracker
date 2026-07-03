/// Per-key monotonic throttle for app-resume side effects.
///
/// Every foreground resume re-fires premium refresh / update checks even
/// when the user flips between apps within seconds; this gate caps those
/// network calls to a sane interval. In-memory only: a cold start always
/// runs everything again by construction.
class ResumeThrottle {
  ResumeThrottle({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, DateTime> _lastRunAt = {};

  /// Returns true (and stamps the key) when [minInterval] has elapsed since
  /// the last allowed run — the caller should then perform the work.
  bool shouldRun(String key, Duration minInterval) {
    final now = _now();
    final last = _lastRunAt[key];
    if (last != null && now.difference(last) < minInterval) return false;
    _lastRunAt[key] = now;
    return true;
  }

  /// Clears all stamps (e.g. on logout, so the next login refreshes fresh).
  void reset() => _lastRunAt.clear();
}
