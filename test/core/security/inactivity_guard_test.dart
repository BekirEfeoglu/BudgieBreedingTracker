import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/security/inactivity_guard.dart';

void main() {
  group('InactivityGuard', () {
    test('does not fire callback before timeout', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        async.elapse(const Duration(minutes: 4, seconds: 59));

        expect(fired, isFalse);

        guard.dispose();
      });
    });

    test('fires onTimeout after timeout period', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        async.elapse(const Duration(minutes: 5));

        expect(fired, isTrue);

        guard.dispose();
      });
    });

    test('recordActivity resets the timer', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        async.elapse(const Duration(minutes: 4));

        // Reset the timer at the 4-minute mark
        guard.recordActivity();
        async.elapse(const Duration(minutes: 4));
        expect(fired, isFalse);

        // Now let the full timeout elapse after the reset
        async.elapse(const Duration(minutes: 1));
        expect(fired, isTrue);

        guard.dispose();
      });
    });

    test('stop prevents timeout from firing', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        async.elapse(const Duration(minutes: 2));
        guard.stop();
        async.elapse(const Duration(minutes: 10));

        expect(fired, isFalse);

        guard.dispose();
      });
    });

    test('start after stop resumes timing', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        async.elapse(const Duration(minutes: 2));
        guard.stop();
        async.elapse(const Duration(minutes: 10));
        expect(fired, isFalse);

        guard.start();
        async.elapse(const Duration(minutes: 5));
        expect(fired, isTrue);

        guard.dispose();
      });
    });

    test('dispose prevents further timeouts', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.start();
        guard.dispose();
        async.elapse(const Duration(minutes: 10));

        expect(fired, isFalse);
      });
    });

    test('recordActivity does nothing when not running', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        // Not started - recordActivity should be a no-op
        guard.recordActivity();
        async.elapse(const Duration(minutes: 10));

        expect(fired, isFalse);

        guard.dispose();
      });
    });

    test('start does nothing after dispose', () {
      fakeAsync((async) {
        var fired = false;
        final guard = InactivityGuard(
          timeout: const Duration(minutes: 5),
          onTimeout: () => fired = true,
        );

        guard.dispose();
        guard.start();
        async.elapse(const Duration(minutes: 10));

        expect(fired, isFalse);
      });
    });

    test('wrapWithListener returns a Listener widget', () {
      final guard = InactivityGuard(
        timeout: const Duration(minutes: 30),
        onTimeout: () {},
      );

      const child = SizedBox();
      final wrapped = guard.wrapWithListener(child: child);

      expect(wrapped, isA<Listener>());
      final listener = wrapped as Listener;
      expect(listener.child, same(child));
      expect(listener.behavior, HitTestBehavior.translucent);

      guard.dispose();
    });
  });
}
