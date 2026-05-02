import 'package:budgie_breeding_tracker/core/enums/update_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateStatus', () {
    test('has three variants', () {
      expect(UpdateStatus.values, hasLength(3));
      expect(UpdateStatus.values, contains(UpdateStatus.none));
      expect(UpdateStatus.values, contains(UpdateStatus.optional));
      expect(UpdateStatus.values, contains(UpdateStatus.forced));
    });

    test('isUpdateAvailable returns true only for optional/forced', () {
      expect(UpdateStatus.none.isUpdateAvailable, isFalse);
      expect(UpdateStatus.optional.isUpdateAvailable, isTrue);
      expect(UpdateStatus.forced.isUpdateAvailable, isTrue);
    });

    test('isBlocking returns true only for forced', () {
      expect(UpdateStatus.none.isBlocking, isFalse);
      expect(UpdateStatus.optional.isBlocking, isFalse);
      expect(UpdateStatus.forced.isBlocking, isTrue);
    });
  });
}
