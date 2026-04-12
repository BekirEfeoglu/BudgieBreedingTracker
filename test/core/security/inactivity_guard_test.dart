import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/security/inactivity_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    group('background lifecycle', () {
      test('fires timeout when background time exceeds timeout', () {
        fakeAsync((async) {
          var fired = false;
          final guard = InactivityGuard(
            timeout: const Duration(minutes: 5),
            onTimeout: () => fired = true,
            clock: () => async.getClock(DateTime(2024)).now(),
          );

          guard.start();
          async.elapse(const Duration(minutes: 1));

          // Simulate going to background
          guard.didChangeAppLifecycleState(AppLifecycleState.paused);
          // 6 minutes pass in background (exceeds 5 min timeout)
          async.elapse(const Duration(minutes: 6));
          // Resume
          guard.didChangeAppLifecycleState(AppLifecycleState.resumed);

          expect(fired, isTrue);

          guard.dispose();
        });
      });

      test('does not fire timeout when background time is within timeout', () {
        fakeAsync((async) {
          var fired = false;
          final guard = InactivityGuard(
            timeout: const Duration(minutes: 5),
            onTimeout: () => fired = true,
            clock: () => async.getClock(DateTime(2024)).now(),
          );

          guard.start();
          async.elapse(const Duration(minutes: 1));

          // Simulate 3 minutes in background (within 5 min timeout)
          guard.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(minutes: 3));
          guard.didChangeAppLifecycleState(AppLifecycleState.resumed);

          expect(fired, isFalse);

          guard.dispose();
        });
      });

      test('uses remaining time after resume, not full timeout', () {
        fakeAsync((async) {
          var fired = false;
          final guard = InactivityGuard(
            timeout: const Duration(minutes: 5),
            onTimeout: () => fired = true,
            clock: () => async.getClock(DateTime(2024)).now(),
          );

          guard.start();
          // Go to background after 0 min, stay 3 min
          guard.didChangeAppLifecycleState(AppLifecycleState.paused);
          async.elapse(const Duration(minutes: 3));
          guard.didChangeAppLifecycleState(AppLifecycleState.resumed);

          // Remaining should be ~2 min, not 5 min
          // After 1 min 59 sec — should NOT have fired
          async.elapse(const Duration(minutes: 1, seconds: 59));
          expect(fired, isFalse);

          // After the remaining 1 second — should fire
          async.elapse(const Duration(seconds: 1));
          expect(fired, isTrue);

          guard.dispose();
        });
      });

      test('timer is cancelled during background', () {
        fakeAsync((async) {
          var fired = false;
          final guard = InactivityGuard(
            timeout: const Duration(minutes: 5),
            onTimeout: () => fired = true,
            clock: () => async.getClock(DateTime(2024)).now(),
          );

          guard.start();
          async.elapse(const Duration(minutes: 4));
          // Go to background — timer should be cancelled
          guard.didChangeAppLifecycleState(AppLifecycleState.paused);
          // Even though original timer would have fired at 5 min, it shouldn't
          async.elapse(const Duration(minutes: 2));
          expect(fired, isFalse);

          guard.dispose();
        });
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
