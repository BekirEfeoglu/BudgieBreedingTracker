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

/// Admin action types for audit log categorization.
/// Replaces string matching like `action.contains('delete')`.
enum AdminActionType {
  create,
  update,
  delete,
  login,
  logout,
  grantPremium,
  revokePremium,
  toggleActive,
  export,
  reset,
  clearLogs,
  dismissEvent,
  unknown;

  String toJson() => name;
  static AdminActionType fromJson(String json) {
    // Handle snake_case action strings from database
    final normalized = json.toLowerCase().replaceAll('_', '');
    for (final value in values) {
      if (value.name.toLowerCase() == normalized) return value;
    }
    // Fallback: check if the action string contains a known keyword
    if (json.contains('delete') || json.contains('remove')) return delete;
    if (json.contains('create') || json.contains('add')) return create;
    if (json.contains('update') || json.contains('edit')) return update;
    if (json.contains('login')) return login;
    if (json.contains('logout')) return logout;
    if (json.contains('grant') && json.contains('premium')) return grantPremium;
    if (json.contains('revoke') && json.contains('premium')) return revokePremium;
    if (json.contains('toggle') && json.contains('active')) return toggleActive;
    if (json.contains('export')) return export;
    if (json.contains('reset')) return reset;
    if (json.contains('clear') && json.contains('log')) return clearLogs;
    if (json.contains('dismiss')) return dismissEvent;
    return unknown;
  }
}

/// Security event types for type-safe severity inference.
/// Replaces string pattern matching like `eventType.contains('suspicious')`.
enum SecurityEventType {
  failedLogin,
  suspiciousActivity,
  rateLimited,
  bruteForce,
  unauthorizedAccess,
  mfaFailure,
  unknown;

  String toJson() => name;
  static SecurityEventType fromJson(String json) {
    final lower = json.toLowerCase().replaceAll('_', '');
    for (final value in values) {
      if (value.name.toLowerCase() == lower) return value;
    }
    // Fallback keyword matching for legacy data
    if (json.contains('failed') && json.contains('login')) return failedLogin;
    if (json.contains('suspicious')) return suspiciousActivity;
    if (json.contains('rate_limit') || json.contains('ratelimit')) return rateLimited;
    if (json.contains('brute')) return bruteForce;
    if (json.contains('unauthorized')) return unauthorizedAccess;
    if (json.contains('mfa')) return mfaFailure;
    return unknown;
  }

  /// Infer severity from event type — replaces fragile string matching in widgets.
  SecuritySeverityLevel get inferredSeverity => switch (this) {
    bruteForce || unauthorizedAccess => SecuritySeverityLevel.high,
    suspiciousActivity || mfaFailure => SecuritySeverityLevel.medium,
    failedLogin || rateLimited => SecuritySeverityLevel.low,
    unknown => SecuritySeverityLevel.unknown,
  };
}
