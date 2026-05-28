import 'package:budgie_breeding_tracker/domain/services/app_update/in_app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements InAppUpdateClient {}

void main() {
  late _MockClient client;
  late InAppUpdateService service;

  setUp(() {
    client = _MockClient();
    service = InAppUpdateService(client);
    when(() => client.startImmediate()).thenAnswer((_) async {});
    when(() => client.startFlexible()).thenAnswer((_) async {});
  });

  UpdateCheck check({
    bool available = true,
    bool immediate = true,
    bool flexible = true,
    int priority = 0,
  }) => UpdateCheck(
        available: available,
        immediateAllowed: immediate,
        flexibleAllowed: flexible,
        priority: priority,
      );

  test('no update available -> does nothing', () async {
    when(() => client.check())
        .thenAnswer((_) async => check(available: false));
    await service.checkAndStart();
    verifyNever(() => client.startImmediate());
    verifyNever(() => client.startFlexible());
  });

  test('high priority + immediate allowed -> immediate update', () async {
    when(() => client.check())
        .thenAnswer((_) async => check(priority: 5));
    await service.checkAndStart();
    verify(() => client.startImmediate()).called(1);
    verifyNever(() => client.startFlexible());
  });

  test('low priority -> flexible update', () async {
    when(() => client.check())
        .thenAnswer((_) async => check(priority: 0));
    await service.checkAndStart();
    verify(() => client.startFlexible()).called(1);
    verifyNever(() => client.startImmediate());
  });

  test('high priority but immediate not allowed -> flexible', () async {
    when(() => client.check())
        .thenAnswer((_) async => check(immediate: false, priority: 5));
    await service.checkAndStart();
    verify(() => client.startFlexible()).called(1);
    verifyNever(() => client.startImmediate());
  });

  test('no flow allowed -> does nothing', () async {
    when(() => client.check()).thenAnswer(
      (_) async => check(immediate: false, flexible: false, priority: 5),
    );
    await service.checkAndStart();
    verifyNever(() => client.startImmediate());
    verifyNever(() => client.startFlexible());
  });

  test('check throws -> swallowed (fail-open)', () async {
    when(() => client.check()).thenThrow(Exception('play services missing'));
    await expectLater(service.checkAndStart(), completes);
  });

  test('priority exactly at threshold (4) -> immediate', () async {
    when(() => client.check()).thenAnswer((_) async => check(priority: 4));
    await service.checkAndStart();
    verify(() => client.startImmediate()).called(1);
    verifyNever(() => client.startFlexible());
  });

  test('priority one below threshold (3) -> flexible', () async {
    when(() => client.check()).thenAnswer((_) async => check(priority: 3));
    await service.checkAndStart();
    verify(() => client.startFlexible()).called(1);
    verifyNever(() => client.startImmediate());
  });
}
