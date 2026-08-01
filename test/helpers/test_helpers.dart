import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

import 'mocks.dart';

// Consolidated: createTestBird and createInbredPedigree are now in
// test_fixtures.dart. This file re-exports them for backward compatibility.
export 'test_fixtures.dart' show createTestBird, createInbredPedigree;

/// Provides a server-verified premium response for provider tests.
List<dynamic> verifiedPremiumServerOverrides(bool Function() isPremium) {
  final edgeClient = MockEdgeFunctionClient();
  when(() => edgeClient.invoke('sync-premium-status')).thenAnswer((_) async {
    return EdgeFunctionResult(success: true, data: {'is_premium': isPremium()});
  });

  return [
    edgeFunctionClientProvider.overrideWithValue(edgeClient),
    premiumActivationSyncDelayProvider.overrideWithValue((_) async {}),
  ];
}

/// Polls [predicate] every [interval] for up to [maxAttempts] iterations.
/// Returns as soon as [predicate] returns true.
///
/// Useful for waiting on async Notifier side-effects in provider tests.
Future<void> waitUntil(
  bool Function() predicate, {
  int maxAttempts = 500,
  Duration interval = const Duration(milliseconds: 1),
}) async {
  var nextDelay = interval;
  for (var i = 0; i < maxAttempts; i++) {
    if (predicate()) return;
    await Future<void>.delayed(nextDelay);
    await Future<void>.delayed(Duration.zero);
    if (nextDelay < const Duration(milliseconds: 16)) {
      nextDelay *= 2;
    }
  }

  throw TestFailure(
    'waitUntil timed out after $maxAttempts attempts with interval '
    '$interval.',
  );
}
