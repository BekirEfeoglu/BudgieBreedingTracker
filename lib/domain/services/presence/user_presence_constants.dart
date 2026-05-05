abstract final class UserPresenceConstants {
  static const Duration heartbeatInterval = Duration(minutes: 2);
  static const Duration onlineThreshold = Duration(minutes: 5);
  static const Duration sessionTtl = Duration(minutes: 10);
}
