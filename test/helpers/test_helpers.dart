import 'package:flutter_test/flutter_test.dart';

// Consolidated: createTestBird and createInbredPedigree are now in
// test_fixtures.dart. This file re-exports them for backward compatibility.
export 'test_fixtures.dart' show createTestBird, createInbredPedigree;

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
