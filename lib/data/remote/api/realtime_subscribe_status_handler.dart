import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeSubscribeStatus;

import '../../../core/utils/realtime_error_log_throttle.dart';

/// Applies the correct log/reset policy for a realtime channel's `subscribe`
/// status callback, shared by every `*RemoteSource` that opens a channel.
///
/// The Supabase realtime SDK reports `closed`, `timedOut`, and `subscribed`
/// with a **null** error, and only `channelError` with a non-null error
/// (see `realtime_client`'s `realtime_channel.dart`). During a failing
/// reconnect loop the channel cycles `channelError → timedOut/closed →
/// channelError → …`, so resetting the throttle on *any* null-error status —
/// as the call sites previously did — cleared the warning budget between every
/// error. That defeated [RealtimeErrorLogThrottle] entirely: every retry logged
/// at warning level forever, flooding logs and displacing Sentry breadcrumbs.
///
/// Correct policy:
/// - `subscribed` → genuine (re)connect success → reset the budget.
/// - `channelError` / `timedOut` → failures → log (throttled).
/// - `closed` → transient teardown between reconnect attempts → ignore
///   (neither log nor reset), so the cap survives the loop.
void handleRealtimeSubscribeStatus({
  required RealtimeSubscribeStatus status,
  required RealtimeErrorLogThrottle throttle,
  required String message,
}) {
  switch (status) {
    case RealtimeSubscribeStatus.subscribed:
      throttle.reset();
    case RealtimeSubscribeStatus.channelError:
    case RealtimeSubscribeStatus.timedOut:
      throttle.logError(message);
    case RealtimeSubscribeStatus.closed:
      break;
  }
}
