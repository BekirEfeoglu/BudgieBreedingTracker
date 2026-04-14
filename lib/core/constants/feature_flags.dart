/// Compile-time feature flags for features under development.
/// Set a flag to `true` and rebuild to enable the feature.
/// Tree-shaking removes dead code when a flag is `false`.
abstract final class FeatureFlags {
  static const bool communityEnabled = true;
  static const bool marketplaceEnabled = true;
  static const bool messagingEnabled = false;
  static const bool gamificationEnabled = false;
}
