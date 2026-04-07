import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _FakeEdgeFunctionClient extends EdgeFunctionClient {
  final EdgeFunctionResult? _fixedResult;
  final bool shouldThrow;

  _FakeEdgeFunctionClient({
    EdgeFunctionResult? fixedResult,
    this.shouldThrow = false,
  })  : _fixedResult = fixedResult,
        super(_MockSupabaseClient());

  @override
  Future<EdgeFunctionResult> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return _fixedResult ??
        const EdgeFunctionResult(success: true, data: {'allowed': true});
  }
}

void main() {
  late FreeTierLimitService service;
  late MockBirdRepository mockBirdRepo;
  late MockBreedingPairRepository mockBreedingRepo;
  late MockIncubationRepository mockIncubationRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    mockBreedingRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    service = FreeTierLimitService(
      birdRepo: mockBirdRepo,
      breedingPairRepo: mockBreedingRepo,
      incubationRepo: mockIncubationRepo,
    );
  });

  group('guardBirdLimit', () {
    test('does not throw when under limit', () async {
      when(() => mockBirdRepo.getCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBirds - 1);

      await service.guardBirdLimit('u1');

      verify(() => mockBirdRepo.getCount('u1')).called(1);
    });

    test('throws FreeTierLimitException at limit', () async {
      when(() => mockBirdRepo.getCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBirds);

      await expectLater(
        service.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('throws FreeTierLimitException above limit', () async {
      when(() => mockBirdRepo.getCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBirds + 2);

      await expectLater(
        service.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('does not throw when count is zero', () async {
      when(() => mockBirdRepo.getCount('u1')).thenAnswer((_) async => 0);

      await service.guardBirdLimit('u1');

      verify(() => mockBirdRepo.getCount('u1')).called(1);
    });
  });

  group('guardBreedingPairLimit', () {
    test('does not throw when active count is zero', () async {
      when(() => mockBreedingRepo.getActiveCount('u1'))
          .thenAnswer((_) async => 0);

      await service.guardBreedingPairLimit('u1');

      verify(() => mockBreedingRepo.getActiveCount('u1')).called(1);
    });

    test('does not throw when under limit', () async {
      when(() => mockBreedingRepo.getActiveCount('u1'))
          .thenAnswer((_) async => 1);

      await service.guardBreedingPairLimit('u1');

      verify(() => mockBreedingRepo.getActiveCount('u1')).called(1);
    });

    test('throws when active pairs reach limit', () async {
      when(() => mockBreedingRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBreedingPairs);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('throws when active pairs exceed limit', () async {
      when(() => mockBreedingRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBreedingPairs + 3);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('counts both active and ongoing pairs together', () async {
      // getActiveCount already combines active + ongoing at SQL level
      when(() => mockBreedingRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxBreedingPairs);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });
  });

  group('guardIncubationLimit', () {
    test('does not throw when count is zero', () async {
      when(() => mockIncubationRepo.getActiveCount('u1'))
          .thenAnswer((_) async => 0);

      await service.guardIncubationLimit('u1');

      verify(() => mockIncubationRepo.getActiveCount('u1')).called(1);
    });

    test('does not throw when under limit', () async {
      when(() => mockIncubationRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxActiveIncubations - 1);

      await service.guardIncubationLimit('u1');

      verify(() => mockIncubationRepo.getActiveCount('u1')).called(1);
    });

    test('throws when active incubations reach limit', () async {
      when(() => mockIncubationRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxActiveIncubations);

      await expectLater(
        service.guardIncubationLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('throws when active incubations exceed limit', () async {
      when(() => mockIncubationRepo.getActiveCount('u1'))
          .thenAnswer((_) async => AppConstants.freeTierMaxActiveIncubations + 5);

      await expectLater(
        service.guardIncubationLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });
  });

  group('server-side validation', () {
    late FreeTierLimitService serviceWithServer;
    late MockBirdRepository mockBirdRepo;
    late MockBreedingPairRepository mockBreedingRepo;
    late MockIncubationRepository mockIncubationRepo;

    setUp(() {
      mockBirdRepo = MockBirdRepository();
      mockBreedingRepo = MockBreedingPairRepository();
      mockIncubationRepo = MockIncubationRepository();
    });

    test('passes when server allows', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'allowed': true},
        ),
      );
      serviceWithServer = FreeTierLimitService(
        birdRepo: mockBirdRepo,
        breedingPairRepo: mockBreedingRepo,
        incubationRepo: mockIncubationRepo,
        edgeFunctionClient: edgeClient,
      );
      when(() => mockBirdRepo.getCount('u1')).thenAnswer((_) async => 0);

      // Should not throw
      await serviceWithServer.guardBirdLimit('u1');
    });

    test('throws FreeTierLimitException when server rejects', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: true,
          data: {'allowed': false, 'limit': 10},
        ),
      );
      serviceWithServer = FreeTierLimitService(
        birdRepo: mockBirdRepo,
        breedingPairRepo: mockBreedingRepo,
        incubationRepo: mockIncubationRepo,
        edgeFunctionClient: edgeClient,
      );
      when(() => mockBirdRepo.getCount('u1')).thenAnswer((_) async => 0);

      await expectLater(
        serviceWithServer.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('silently passes when server is unavailable', () async {
      final edgeClient = _FakeEdgeFunctionClient(
        fixedResult: const EdgeFunctionResult(
          success: false,
          error: 'Function not deployed',
        ),
      );
      serviceWithServer = FreeTierLimitService(
        birdRepo: mockBirdRepo,
        breedingPairRepo: mockBreedingRepo,
        incubationRepo: mockIncubationRepo,
        edgeFunctionClient: edgeClient,
      );
      when(() => mockBirdRepo.getCount('u1')).thenAnswer((_) async => 0);

      // Should not throw — client-side guard already passed
      await serviceWithServer.guardBirdLimit('u1');
    });

    test('silently passes when server throws network error', () async {
      final edgeClient = _FakeEdgeFunctionClient(shouldThrow: true);
      serviceWithServer = FreeTierLimitService(
        birdRepo: mockBirdRepo,
        breedingPairRepo: mockBreedingRepo,
        incubationRepo: mockIncubationRepo,
        edgeFunctionClient: edgeClient,
      );
      when(() => mockBirdRepo.getCount('u1')).thenAnswer((_) async => 0);

      // Should not throw — network errors are non-blocking
      await serviceWithServer.guardBirdLimit('u1');
    });
  });
}
