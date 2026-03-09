import 'package:budgie_breeding_tracker/core/utils/navigation_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    // NavigationThrottle keeps static state, wait enough to avoid cross-test bleed.
    await Future<void>.delayed(const Duration(milliseconds: 60));
  });

  test('blocks rapid duplicate navigation attempts', () {
    final first = NavigationThrottle.canNavigate(
      cooldown: const Duration(milliseconds: 50),
    );
    final second = NavigationThrottle.canNavigate(
      cooldown: const Duration(milliseconds: 50),
    );

    expect(first, isTrue);
    expect(second, isFalse);
  });

  test('allows navigation again after cooldown expires', () async {
    final first = NavigationThrottle.canNavigate(
      cooldown: const Duration(milliseconds: 30),
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));

    final second = NavigationThrottle.canNavigate(
      cooldown: const Duration(milliseconds: 30),
    );

    expect(first, isTrue);
    expect(second, isTrue);
  });
}
