import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anonymous sign-ins are disabled for account-scoped data', () {
    final config = File('supabase/config.toml').readAsStringSync();
    final disabled = RegExp(
      r'^\s*enable_anonymous_sign_ins\s*=\s*false\s*$',
      multiLine: true,
    ).hasMatch(config);

    expect(disabled, isTrue);
  });
}
