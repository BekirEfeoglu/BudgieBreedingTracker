part of 'bootstrap.dart';

String _preferNonEmpty(String primary, Object? fallback) {
  final trimmedPrimary = primary.trim();
  if (trimmedPrimary.isNotEmpty) return trimmedPrimary;
  return fallback?.toString().trim() ?? '';
}

/// Validates that the Supabase URL looks like a real project URL.
bool _isValidSupabaseUrl(String url) {
  if (url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  // Reject common placeholder values
  const placeholders = ['placeholder', 'your-project', 'example', 'test'];
  final host = uri.host.toLowerCase();
  return !placeholders.any((p) => host.contains(p));
}

/// Validates that the Supabase client key looks like a real JWT anon key
/// or a modern `sb_publishable_...` key.
bool _isValidSupabaseApiKey(String key) {
  if (key.isEmpty) return false;
  final trimmedKey = key.trim();

  if (trimmedKey.startsWith('sb_publishable_')) {
    const placeholders = ['placeholder', 'your-key', 'example'];
    final lower = trimmedKey.toLowerCase();
    return !placeholders.any((p) => lower.contains(p));
  }

  final parts = trimmedKey.split('.');
  if (parts.length != 3) return false;
  // Reject common placeholder values — only check the header segment
  // to avoid false positives from base64 payload containing "test".
  const placeholders = ['placeholder', 'your-anon', 'example'];
  final lower = parts.first.toLowerCase();
  return !placeholders.any((p) => lower.contains(p));
}

@visibleForTesting
bool debugIsValidSupabaseUrl(String url) => _isValidSupabaseUrl(url);

@visibleForTesting
bool debugIsValidSupabaseApiKey(String key) => _isValidSupabaseApiKey(key);
