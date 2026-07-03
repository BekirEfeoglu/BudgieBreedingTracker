import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/utils/resume_throttle.dart';

void main() {
  group('ResumeThrottle', () {
    test('should run first call and block second within interval', () {
      var t = DateTime(2026, 7, 3, 10, 0, 0);
      final throttle = ResumeThrottle(now: () => t);

      expect(throttle.shouldRun('premium', const Duration(minutes: 5)), isTrue);
      t = t.add(const Duration(minutes: 4));
      expect(
        throttle.shouldRun('premium', const Duration(minutes: 5)),
        isFalse,
      );
      t = t.add(const Duration(minutes: 2));
      expect(throttle.shouldRun('premium', const Duration(minutes: 5)), isTrue);
    });

    test('should track keys independently', () {
      final t = DateTime(2026, 7, 3);
      final throttle = ResumeThrottle(now: () => t);
      expect(throttle.shouldRun('a', const Duration(hours: 6)), isTrue);
      expect(throttle.shouldRun('b', const Duration(hours: 6)), isTrue);
    });

    test('should run again after reset', () {
      final t = DateTime(2026, 7, 3);
      final throttle = ResumeThrottle(now: () => t);
      throttle.shouldRun('premium', const Duration(minutes: 5));
      throttle.reset();
      expect(throttle.shouldRun('premium', const Duration(minutes: 5)), isTrue);
    });
  });
}
