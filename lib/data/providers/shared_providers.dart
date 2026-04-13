/// Barrel file for shared providers that are used across feature modules.
///
/// Features should import from this file (or individual files in this
/// directory) instead of importing directly from other features.
/// This prevents cross-feature import violations.
library;

export 'action_feedback_providers.dart';
export 'auth_state_providers.dart';
export 'bird_stream_providers.dart';
export 'breeding_detail_stream_providers.dart';
export 'breeding_stream_providers.dart';
export 'chick_stream_providers.dart';
export 'date_format_providers.dart';
export 'egg_stream_providers.dart';
export 'health_record_stream_providers.dart';
export 'notification_settings_shared_providers.dart';
export 'premium_shared_providers.dart';
export 'profile_stream_providers.dart';
