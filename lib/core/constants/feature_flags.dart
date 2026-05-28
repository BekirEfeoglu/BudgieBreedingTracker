/// Compile-time feature flags for features under development.
/// Set a flag to `true` and rebuild to enable the feature.
/// Tree-shaking removes dead code when a flag is `false`.
abstract final class FeatureFlags {
  static const bool communityEnabled = true;
  static const bool marketplaceEnabled = true;
  static const bool messagingEnabled = false;
  static const bool gamificationEnabled = false;

  /// Image/bird/listing message attachments. Disabled because the UI exists
  /// but the upload pipeline (image picker → scan-image-safety → Storage →
  /// send) is not wired (Messaging audit C1+C2). Flip to `true` after
  /// implementing the pipeline AND removing the empty-onTap ListTiles.
  static const bool messageAttachmentsEnabled = false;
}
