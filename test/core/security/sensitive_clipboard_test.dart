import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/security/sensitive_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('clears copied sensitive text after the configured TTL', () async {
    final clipboardWrites = <String?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<Object?, Object?>;
            clipboardWrites.add(args['text'] as String?);
          }
          return null;
        });

    await SensitiveClipboard.copyText(
      'totp-secret',
      clearAfter: const Duration(milliseconds: 1),
    );
    expect(clipboardWrites, ['totp-secret']);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(clipboardWrites, ['totp-secret', '']);
  });
}
