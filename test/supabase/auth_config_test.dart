import 'dart:io';

import 'package:budgie_breeding_tracker/core/constants/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anonymous sign-ins are disabled in client and Supabase', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final disabled = RegExp(
      r'^\s*enable_anonymous_sign_ins\s*=\s*false\s*$',
      multiLine: true,
    ).hasMatch(config);

    expect(disabled, isTrue);
    expect(FeatureFlags.anonymousSignInEnabled, isFalse);
  });

  test('local email capture uses the supported local_smtp config section', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final localSmtp = RegExp(
      r'^\s*\[local_smtp\]\s*$',
      multiLine: true,
    ).hasMatch(config);
    final deprecatedInbucket = RegExp(
      r'^\s*\[inbucket\]\s*$',
      multiLine: true,
    ).hasMatch(config);

    expect(localSmtp, isTrue);
    expect(deprecatedInbucket, isFalse);
  });
}
