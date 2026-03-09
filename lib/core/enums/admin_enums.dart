// Admin-specific enums for type safety.

/// Alert severity levels for system alerts.
enum AlertSeverity {
  critical,
  warning,
  info,
  unknown;

  String toJson() => name;
  static AlertSeverity fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return AlertSeverity.unknown;
    }
  }
}

/// Security event severity levels.
enum SecuritySeverityLevel {
  high,
  medium,
  low,
  unknown;

  String toJson() => name;
  static SecuritySeverityLevel fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return SecuritySeverityLevel.unknown;
    }
  }
}

/// Admin user roles.
enum AdminRole {
  founder,
  moderator,
  unknown;

  String toJson() => name;
  static AdminRole fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return AdminRole.unknown;
    }
  }
}

/// Feedback ticket status.
enum FeedbackStatus {
  open,
  pending,
  resolved,
  unknown;

  String toJson() => name;
  static FeedbackStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return FeedbackStatus.unknown;
    }
  }
}
