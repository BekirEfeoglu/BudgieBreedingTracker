/// Re-exports user role providers (admin / founder) for cross-feature use.
///
/// The implementation lives in
/// `lib/features/admin/providers/admin_data_providers.dart`.
/// This shim exists so non-admin features (auth, profile, community, more,
/// router) can watch role state without importing the `admin` feature
/// directly — avoiding cross-feature import violations.
library;

export 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart'
    show isAdminProvider, isFounderProvider;
