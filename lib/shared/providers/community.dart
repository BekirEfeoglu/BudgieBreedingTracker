// Shared exports from the community feature for cross-feature reuse.
//
// Currently exposes blockedUsersProvider so messaging can apply the
// same block list to DM creation / conversation filtering without
// crossing the feature boundary directly. Block state is intentionally
// owned by community for now; if it grows past two feature consumers
// it should move to core/data/providers.
export 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart'
    show blockedUsersProvider;
