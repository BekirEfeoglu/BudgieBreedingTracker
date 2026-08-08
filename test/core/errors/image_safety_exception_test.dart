import 'package:budgie_breeding_tracker/core/errors/image_safety_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

void main() {
  test(
    'preserves the storage exception contract with a stable reason code',
    () {
      const exception = ImageSafetyException(
        'Image rejected: safety_scan_rate_limited',
        code: 'safety_scan_rate_limited',
      );

      expect(exception, isA<StorageException>());
      expect(exception.code, 'safety_scan_rate_limited');
      expect(exception.error, 'safety_scan_rate_limited');
    },
  );
}
