/// Compile-time feature flags for features under development.
/// Set a flag to `true` and rebuild to enable the feature.
/// Tree-shaking removes dead code when a flag is `false`.
abstract final class FeatureFlags {
  static const bool communityEnabled = true;
  static const bool marketplaceEnabled = true;
  // Enabled 2026-07-10: the messaging feature is fully built (conversation
  // list, DM/group threads, realtime, read receipts, DM photo attachments) and
  // server-ready (conversations/participants/messages tables + RLS + the
  // message-photos bucket are live in prod). The community message icon and
  // post "send message" action pushed /messages while these routes were gated
  // off, so those entry points dead-ended — enabling the flag registers the
  // routes and makes them work.
  static const bool messagingEnabled = true;
  static const bool gamificationEnabled = true;

  /// Direct-message photo attachments. Bird/listing cards stay hidden until
  /// they have real producers instead of empty bottom-sheet actions.
  static const bool messageAttachmentsEnabled = true;
}
