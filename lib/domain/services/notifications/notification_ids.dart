import 'package:flutter/foundation.dart' show visibleForTesting;

/// Notification ID generation and base offsets.
///
/// Partitions the ID space into categories, each with 100,000 IDs.
/// Within each category, entities get 100-ID "slots" via FNV-1a hashing.
abstract final class NotificationIds {
  /// Base ID offset for egg turning notifications. Range: 100000–199999
  static const eggTurningBaseId = 100000;

  /// Base ID offset for incubation milestone notifications. Range: 200000–299999
  static const incubationBaseId = 200000;

  /// Base ID offset for health check notifications. Range: 300000–399999
  static const healthCheckBaseId = 300000;

  /// Base ID offset for chick care notifications. Range: 400000–499999
  static const chickCareBaseId = 400000;

  /// Base ID offset for banding reminder notifications. Range: 500000–599999
  static const bandingBaseId = 500000;

  static const idsPerEntitySlot = 100;

  /// Generates a stable notification ID for an entity within a category.
  ///
  /// Partitions each 100,000-ID range into 1,000 entity "slots" of 100 IDs,
  /// preventing collisions between different entities in the same category.
  @visibleForTesting
  static int generate(int baseId, String entityId, int offset) {
    if (offset < 0 || offset >= idsPerEntitySlot) {
      throw RangeError.range(
        offset,
        0,
        idsPerEntitySlot - 1,
        'offset',
        'Offset must stay within entity slot size ($idsPerEntitySlot)',
      );
    }

    // FNV-1a hash for better distribution than hashCode
    var hash = 0x811c9dc5;
    for (var i = 0; i < entityId.length; i++) {
      hash ^= entityId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    final slot = hash % 1000;
    return baseId + slot * 100 + offset;
  }
}
