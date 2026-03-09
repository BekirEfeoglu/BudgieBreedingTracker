import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/genetics_history_dao.dart';

/// Mock repository classes using mocktail.
///
/// Usage:
/// ```dart
/// final mockBirdRepo = MockBirdRepository();
/// when(() => mockBirdRepo.watchAll('user-1'))
///     .thenAnswer((_) => Stream.value([testBird]));
/// ```
class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockChickRepository extends Mock implements ChickRepository {}

class MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class MockGeneticsHistoryDao extends Mock implements GeneticsHistoryDao {}
