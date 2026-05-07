import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anonymous sign-ins are enabled for guest access', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final enabled = RegExp(
      r'^\s*enable_anonymous_sign_ins\s*=\s*true\s*$',
      multiLine: true,
    ).hasMatch(config);

    expect(enabled, isTrue);
  });
}
