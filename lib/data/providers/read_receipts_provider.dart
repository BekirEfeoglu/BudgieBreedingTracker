import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/preferences/app_preferences.dart';
import '../local/preferences/pref_notifier.dart';

/// Whether the user broadcasts read receipts. When off, the messaging client
/// stops recording read receipts (the sender never learns a message was read)
/// AND reciprocally hides other people's read status in the UI. Default on.
///
/// Lives in `data/providers` (not the settings feature) so the messaging
/// feature can enforce it without a cross-feature import. See
/// messaging.md § Read Receipts.
final readReceiptsEnabledProvider =
    NotifierProvider<ReadReceiptsEnabledNotifier, bool>(
      ReadReceiptsEnabledNotifier.new,
    );

class ReadReceiptsEnabledNotifier extends PrefBoolNotifier {
  ReadReceiptsEnabledNotifier()
    : super(AppPreferences.keyReadReceiptsEnabled, defaultValue: true);
}
