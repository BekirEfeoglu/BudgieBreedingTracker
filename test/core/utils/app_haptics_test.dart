import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHaptics — setEnabled', () {
    test('setEnabled(true) does not throw', () {
      expect(() => AppHaptics.setEnabled(true), returnsNormally);
    });

    test('setEnabled(false) does not throw', () {
      expect(() => AppHaptics.setEnabled(false), returnsNormally);
    });
  });

  group('AppHaptics — haptic methods do not throw', () {
    setUp(() {
      // Set haptics to enabled via cache so _isEnabled() does not
      // attempt to access SharedPreferences (unavailable in tests).
      AppHaptics.setEnabled(true);

      // Mock the HapticFeedback platform channel so calls don't crash.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (message) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('lightImpact does not throw', () {
      expect(() => AppHaptics.lightImpact(), returnsNormally);
    });

    test('mediumImpact does not throw', () {
      expect(() => AppHaptics.mediumImpact(), returnsNormally);
    });

    test('heavyImpact does not throw', () {
      expect(() => AppHaptics.heavyImpact(), returnsNormally);
    });

    test('selectionClick does not throw', () {
      expect(() => AppHaptics.selectionClick(), returnsNormally);
    });
  });

  group('AppHaptics — haptic methods when disabled', () {
    setUp(() {
      AppHaptics.setEnabled(false);
    });

    test('lightImpact does not throw when disabled', () {
      expect(() => AppHaptics.lightImpact(), returnsNormally);
    });

    test('mediumImpact does not throw when disabled', () {
      expect(() => AppHaptics.mediumImpact(), returnsNormally);
    });

    test('heavyImpact does not throw when disabled', () {
      expect(() => AppHaptics.heavyImpact(), returnsNormally);
    });

    test('selectionClick does not throw when disabled', () {
      expect(() => AppHaptics.selectionClick(), returnsNormally);
    });
  });

  group('AppHaptics — private constructor', () {
    test('AppHaptics has only static members (private constructor)', () {
      // Verify that AppHaptics is utility class with static-only API.
      // We confirm the public methods exist by calling them.
      AppHaptics.setEnabled(true);
      AppHaptics.lightImpact();
      AppHaptics.mediumImpact();
      AppHaptics.heavyImpact();
      AppHaptics.selectionClick();
    });
  });

  group('AppHaptics — toggle enabled state', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (message) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('can toggle from enabled to disabled without errors', () {
      AppHaptics.setEnabled(true);
      AppHaptics.lightImpact();

      AppHaptics.setEnabled(false);
      AppHaptics.lightImpact();

      AppHaptics.setEnabled(true);
      AppHaptics.lightImpact();
    });
  });
}
