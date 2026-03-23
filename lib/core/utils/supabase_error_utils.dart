/// Returns `true` if [error] indicates Supabase is not initialized.
///
/// Used to silently skip calendar/notification side-effects when running
/// without a Supabase backend (e.g. offline-only or tests).
bool isSupabaseUnavailableError(Object error) {
  final message = error.toString();
  return message.contains('You must initialize the supabase instance') ||
      message.contains('provider that is in error state');
}
