import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

void main() {
  late AppDatabase db;

  const user1 = 'user-1';
  const user2 = 'user-2';
  final ts = DateTime(2024, 1, 1);

  Bird makeBird({
    String id = 'bird-1',
    String user = user1,
    BirdGender gender = BirdGender.male,
    BirdStatus status = BirdStatus.alive,
    bool isDeleted = false,
  }) {
    return Bird(
      id: id, userId: user, name: 'Bird $id', gender: gender,
      status: status, species: Species.budgie,
      isDeleted: isDeleted, createdAt: ts, updatedAt: ts,
    );
  }

  BreedingPair makePair({
    String id = 'bp-1',
    String user = user1,
    String? maleId = 'bird-1',
    String? femaleId = 'bird-2',
    bool isDeleted = false,
  }) {
    return BreedingPair(
      id: id, userId: user, maleId: maleId, femaleId: femaleId,
      status: BreedingStatus.active,
      isDeleted: isDeleted, createdAt: ts, updatedAt: ts,
    );
  }

  Clutch makeClutch({
    String id = 'clutch-1',
    String user = user1,
    String? breedingId = 'bp-1',
    bool isDeleted = false,
  }) {
    return Clutch(
      id: id, userId: user, breedingId: breedingId,
      isDeleted: isDeleted, createdAt: ts, updatedAt: ts,
    );
  }

  Egg makeEgg({
    String id = 'egg-1',
    String user = user1,
    String? clutchId = 'clutch-1',
    EggStatus status = EggStatus.incubating,
    bool isDeleted = false,
  }) {
    return Egg(
      id: id, userId: user, clutchId: clutchId, status: status,
      layDate: ts, isDeleted: isDeleted, createdAt: ts, updatedAt: ts,
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => await db.close());

  group('Cross-DAO data integrity', () {
    test('breeding pair references valid bird IDs', () async {
      await db.birdsDao.insertItem(makeBird(id: 'male-1'));
      await db.birdsDao.insertItem(
        makeBird(id: 'female-1', gender: BirdGender.female),
      );
      await db.breedingPairsDao.insertItem(
        makePair(maleId: 'male-1', femaleId: 'female-1'),
      );

      final pair = await db.breedingPairsDao.getById('bp-1');
      final male = await db.birdsDao.getById(pair!.maleId!);
      final female = await db.birdsDao.getById(pair.femaleId!);
      expect(male, isNotNull);
      expect(female, isNotNull);
      expect(male!.gender, BirdGender.male);
      expect(female!.gender, BirdGender.female);
    });

    test('clutch references valid breeding pair', () async {
      await db.breedingPairsDao.insertItem(makePair());
      await db.clutchesDao.insertItem(makeClutch(breedingId: 'bp-1'));

      final clutch = await db.clutchesDao.getById('clutch-1');
      final pair = await db.breedingPairsDao.getById(clutch!.breedingId!);
      expect(pair, isNotNull);
      expect(pair!.id, 'bp-1');
    });

    test('egg references valid clutch', () async {
      await db.clutchesDao.insertItem(makeClutch());
      await db.eggsDao.insertItem(makeEgg(clutchId: 'clutch-1'));

      final egg = await db.eggsDao.getById('egg-1');
      final clutch = await db.clutchesDao.getById(egg!.clutchId!);
      expect(clutch, isNotNull);
      expect(clutch!.id, 'clutch-1');
    });

    test('full chain: bird -> pair -> clutch -> egg', () async {
      await db.birdsDao.insertItem(makeBird(id: 'm1'));
      await db.birdsDao.insertItem(
        makeBird(id: 'f1', gender: BirdGender.female),
      );
      await db.breedingPairsDao.insertItem(
        makePair(id: 'p1', maleId: 'm1', femaleId: 'f1'),
      );
      await db.clutchesDao.insertItem(makeClutch(id: 'c1', breedingId: 'p1'));
      await db.eggsDao.insertItem(makeEgg(id: 'e1', clutchId: 'c1'));

      final egg = await db.eggsDao.getById('e1');
      final clutch = await db.clutchesDao.getById(egg!.clutchId!);
      final pair = await db.breedingPairsDao.getById(clutch!.breedingId!);
      final male = await db.birdsDao.getById(pair!.maleId!);
      expect(male, isNotNull);
      expect(male!.id, 'm1');
    });
  });

  group('Soft delete cascade awareness', () {
    test('soft-deleted bird does not cascade to breeding pairs', () async {
      await db.birdsDao.insertItem(makeBird(id: 'b1'));
      await db.breedingPairsDao.insertItem(makePair(maleId: 'b1'));
      await db.birdsDao.softDelete('b1');

      final pair = await db.breedingPairsDao.getById('bp-1');
      expect(pair, isNotNull);
      expect(pair!.maleId, 'b1');
    });

    test('watchAll excludes soft-deleted records', () async {
      await db.birdsDao.insertItem(makeBird(id: 'b1'));
      await db.birdsDao.insertItem(makeBird(id: 'b2', isDeleted: true));

      final birds = await db.birdsDao.watchAll(user1).first;
      expect(birds.length, 1);
      expect(birds.first.id, 'b1');
    });

    test('hard delete removes record from getById', () async {
      await db.birdsDao.insertItem(makeBird(id: 'b1'));
      await db.birdsDao.hardDelete('b1');

      final result = await db.birdsDao.getById('b1');
      expect(result, isNull);
    });
  });

  group('User scoping', () {
    test('watchAll isolates birds by userId', () async {
      await db.birdsDao.insertItem(makeBird(id: 'b1', user: user1));
      await db.birdsDao.insertItem(makeBird(id: 'b2', user: user2));

      final u1Birds = await db.birdsDao.watchAll(user1).first;
      final u2Birds = await db.birdsDao.watchAll(user2).first;
      expect(u1Birds.length, 1);
      expect(u1Birds.first.id, 'b1');
      expect(u2Birds.length, 1);
      expect(u2Birds.first.id, 'b2');
    });

    test('getAll isolates breeding pairs by userId', () async {
      await db.breedingPairsDao.insertItem(makePair(id: 'p1', user: user1));
      await db.breedingPairsDao.insertItem(makePair(id: 'p2', user: user2));

      final u1 = await db.breedingPairsDao.getAll(user1);
      final u2 = await db.breedingPairsDao.getAll(user2);
      expect(u1.length, 1);
      expect(u1.first.id, 'p1');
      expect(u2.length, 1);
      expect(u2.first.id, 'p2');
    });

    test('cross-user isolation for clutches and eggs', () async {
      await db.clutchesDao.insertItem(makeClutch(id: 'c1', user: user1));
      await db.clutchesDao.insertItem(makeClutch(id: 'c2', user: user2));
      await db.eggsDao.insertItem(makeEgg(id: 'e1', user: user1));
      await db.eggsDao.insertItem(makeEgg(id: 'e2', user: user2));

      final u1Clutches = await db.clutchesDao.watchAll(user1).first;
      final u2Eggs = await db.eggsDao.getAll(user2);
      expect(u1Clutches.length, 1);
      expect(u2Eggs.length, 1);
      expect(u2Eggs.first.id, 'e2');
    });
  });

  group('Batch operations', () {
    test('insertAll with 50 birds retrieves all', () async {
      final birds = List.generate(
        50, (i) => makeBird(id: 'b-$i'),
      );
      await db.birdsDao.insertAll(birds);

      final all = await db.birdsDao.getAll(user1);
      expect(all.length, 50);
    });

    test('insertAll with empty list does not error', () async {
      await expectLater(db.birdsDao.insertAll([]), completes);
    });

    test('insertAll with duplicate IDs upserts (last wins)', () async {
      final first = makeBird(id: 'dup-1', status: BirdStatus.alive);
      final second = makeBird(id: 'dup-1', status: BirdStatus.dead);
      await db.birdsDao.insertAll([first, second]);

      final result = await db.birdsDao.getById('dup-1');
      expect(result!.status, BirdStatus.dead);
    });
  });

  group('Stream reactivity', () {
    test('watchAll emits updated list after insert', () async {
      final stream = db.birdsDao.watchAll(user1);

      // First emission should be empty, then insert triggers second
      final future = expectLater(
        stream,
        emitsInOrder([
          hasLength(0),
          hasLength(1),
        ]),
      );

      // Small delay to ensure stream subscription is active
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await db.birdsDao.insertItem(makeBird(id: 'r1'));
      await future;
    });

    test('watchAll emits updated list after soft delete', () async {
      await db.birdsDao.insertItem(makeBird(id: 'r1'));
      final stream = db.birdsDao.watchAll(user1);
      final future = expectLater(
        stream,
        emitsInOrder([
          hasLength(1),
          hasLength(0),
        ]),
      );

      await db.birdsDao.softDelete('r1');
      await future;
    });

    test('watchById emits null after hard delete', () async {
      await db.birdsDao.insertItem(makeBird(id: 'r1'));
      final stream = db.birdsDao.watchById('r1');
      final future = expectLater(
        stream,
        emitsInOrder([
          isNotNull,
          isNull,
        ]),
      );

      await db.birdsDao.hardDelete('r1');
      await future;
    });
  });
}
