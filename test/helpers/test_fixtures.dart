import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

class TestFixtures {
  static Bird sampleBird({
    String id = 'bird-1',
    String name = 'Mavis',
    BirdGender gender = BirdGender.male,
    String userId = 'user-1',
    BirdStatus status = BirdStatus.alive,
  }) {
    return Bird(
      id: id,
      name: name,
      gender: gender,
      userId: userId,
      status: status,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  static Egg sampleEgg({
    String id = 'egg-1',
    String userId = 'user-1',
    DateTime? layDate,
    EggStatus status = EggStatus.laid,
    String? clutchId,
    String? incubationId,
  }) {
    return Egg(
      id: id,
      userId: userId,
      layDate: layDate ?? DateTime(2024, 1, 10),
      status: status,
      clutchId: clutchId,
      incubationId: incubationId,
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 1, 10),
    );
  }

  static Chick sampleChick({
    String id = 'chick-1',
    String userId = 'user-1',
    BirdGender gender = BirdGender.unknown,
    DateTime? hatchDate,
    String? eggId,
    String? clutchId,
  }) {
    return Chick(
      id: id,
      userId: userId,
      gender: gender,
      hatchDate: hatchDate ?? DateTime(2024, 1, 28),
      eggId: eggId,
      clutchId: clutchId,
      createdAt: DateTime(2024, 1, 28),
      updatedAt: DateTime(2024, 1, 28),
    );
  }

  static BreedingPair sampleBreedingPair({
    String id = 'pair-1',
    String userId = 'user-1',
    String? maleId = 'bird-1',
    String? femaleId = 'bird-2',
    BreedingStatus status = BreedingStatus.active,
  }) {
    return BreedingPair(
      id: id,
      userId: userId,
      maleId: maleId,
      femaleId: femaleId,
      status: status,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  static Clutch sampleClutch({
    String id = 'clutch-1',
    String userId = 'user-1',
    String? breedingId = 'pair-1',
    String? incubationId,
  }) {
    return Clutch(
      id: id,
      userId: userId,
      breedingId: breedingId,
      incubationId: incubationId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  static SyncMetadata sampleSyncMetadata({
    String id = 'sync-1',
    String table = 'birds',
    String userId = 'user-1',
    String? recordId = 'bird-1',
    SyncStatus status = SyncStatus.pending,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncMetadata(
      id: id,
      table: table,
      userId: userId,
      recordId: recordId,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }
}
