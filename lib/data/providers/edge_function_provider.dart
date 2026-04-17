/// Re-exports the Supabase Edge Function client provider for cross-feature use.
///
/// The implementation lives in
/// `lib/features/admin/providers/admin_data_providers.dart` for historical
/// reasons, but the client itself is generic (used by auth 2FA lockout,
/// admin health, admin notifications, etc.). This shim lets non-admin
/// features depend on it without a cross-feature import violation.
library;

export 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart'
    show edgeFunctionClientProvider;
