import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Runner entitlements enable Sign in with Apple', () {
    final entitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();

    expect(
      entitlements,
      contains('<key>com.apple.developer.applesignin</key>'),
    );
    expect(entitlements, contains('<string>Default</string>'));
  });

  test('Xcode target declares Sign in with Apple capability', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(project, contains('com.apple.SignInWithApple'));
  });
}
