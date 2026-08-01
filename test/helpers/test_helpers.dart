import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/providers/edge_function_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

import 'mocks.dart';

// Consolidated: createTestBird and createInbredPedigree are now in
// test_fixtures.dart. This file re-exports them for backward compatibility.
export 'test_fixtures.dart' show createTestBird, createInbredPedigree;

/// Provides a server-verified premium response without weakening the
/// production purchase flow in provider tests.
List<dynamic> verifiedPremiumServerOverrides(bool Function() isPremium) {
  final edgeClient = MockEdgeFunctionClient();
  final profileRepository = MockProfileRepository();

  when(() => edgeClient.invoke('sync-premium-status')).thenAnswer((_) async {
    final premium = isPremium();
    return EdgeFunctionResult(
      success: true,
      data: {
        'is_premium': premium,
        'subscription_status': premium ? 'premium' : 'free',
      },
    );
  });

  for (final status in [SubscriptionStatus.premium, SubscriptionStatus.free]) {
    when(
      () => profileRepository.applyVerifiedPremiumStatus(
        userId: any(named: 'userId'),
        isPremium: any(named: 'isPremium'),
        subscriptionStatus: status,
        premiumExpiresAt: null,
        gracePeriodUntil: null,
      ),
    ).thenAnswer((_) async {});
  }

  return [
    edgeFunctionClientProvider.overrideWithValue(edgeClient),
    profileRepositoryProvider.overrideWithValue(profileRepository),
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
