/// Prevents rapid duplicate navigations (debounce for navigation taps).
abstract class NavigationThrottle {
  static DateTime? _lastNavTime;

  /// Returns `true` if navigation should proceed, `false` if throttled.
  static bool canNavigate({
    Duration cooldown = const Duration(milliseconds: 500),
  }) {
    final now = DateTime.now();
    if (_lastNavTime != null && now.difference(_lastNavTime!) < cooldown) {
      return false;
    }
    _lastNavTime = now;
    return true;
  }
}
