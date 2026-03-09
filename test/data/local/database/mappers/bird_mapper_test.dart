import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/bird_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

void main() {
  group('BirdRowMapper.toModel()', () {
    test('maps all required fields correctly', () {
      const row = BirdRow(
        id: 'b1',
        name: 'Tweety',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'b1');
      expect(model.name, 'Tweety');
      expect(model.gender, BirdGender.male);
      expect(model.userId, 'u1');
      expect(model.status, BirdStatus.alive);
      expect(model.species, Species.budgie);
      expect(model.isDeleted, false);
    });

    test('maps nullable fields correctly', () {
      final date = DateTime(2024, 6, 1);
      final row = BirdRow(
        id: 'b2',
        name: 'Sky',
        gender: BirdGender.female,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        ringNumber: 'R-123',
        photoUrl: 'https://example.com/photo.jpg',
        fatherId: 'f1',
        motherId: 'm1',
        colorMutation: BirdColor.blue,
        cageNumber: 'C-1',
        notes: 'Some notes',
        birthDate: date,
        deathDate: null,
        soldDate: null,
        createdAt: date,
        updatedAt: date,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.ringNumber, 'R-123');
      expect(model.photoUrl, 'https://example.com/photo.jpg');
      expect(model.fatherId, 'f1');
      expect(model.motherId, 'm1');
      expect(model.colorMutation, BirdColor.blue);
      expect(model.cageNumber, 'C-1');
      expect(model.notes, 'Some notes');
      expect(model.birthDate, date);
    });

    test('decodes mutations JSON list', () {
      const row = BirdRow(
        id: 'b3',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        mutations: '["blue","opaline"]',
      );
      final model = row.toModel();

      expect(model.mutations, ['blue', 'opaline']);
    });

    test('decodes genotypeInfo JSON map', () {
      const row = BirdRow(
        id: 'b4',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        genotypeInfo: '{"blue":"visual","opaline":"split"}',
      );
      final model = row.toModel();

      expect(model.genotypeInfo, {'blue': 'visual', 'opaline': 'split'});
    });

    test('returns null for null mutations', () {
      const row = BirdRow(
        id: 'b5',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        mutations: null,
      );
      final model = row.toModel();

      expect(model.mutations, isNull);
    });

    test('returns null for empty mutations string', () {
      const row = BirdRow(
        id: 'b6',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        mutations: '',
      );
      final model = row.toModel();

      expect(model.mutations, isNull);
    });

    test('returns null for invalid JSON mutations', () {
      const row = BirdRow(
        id: 'b7',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        mutations: 'not valid json',
      );
      final model = row.toModel();

      expect(model.mutations, isNull);
    });

    test('returns null for invalid JSON genotypeInfo', () {
      const row = BirdRow(
        id: 'b8',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        isDeleted: false,
        genotypeInfo: 'invalid',
      );
      final model = row.toModel();

      expect(model.genotypeInfo, isNull);
    });
  });

  group('BirdModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = Bird(
        id: 'b1',
        name: 'Tweety',
        gender: BirdGender.male,
        userId: 'u1',
        status: BirdStatus.alive,
        species: Species.budgie,
        ringNumber: 'R-123',
        fatherId: 'f1',
        motherId: 'm1',
        colorMutation: BirdColor.green,
        cageNumber: 'C-1',
        notes: 'Notes',
        isDeleted: false,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'b1');
      expect(companion.name.value, 'Tweety');
      expect(companion.gender.value, BirdGender.male);
      expect(companion.userId.value, 'u1');
      expect(companion.status.value, BirdStatus.alive);
      expect(companion.species.value, Species.budgie);
      expect(companion.ringNumber.value, 'R-123');
      expect(companion.fatherId.value, 'f1');
      expect(companion.motherId.value, 'm1');
      expect(companion.colorMutation.value, BirdColor.green);
      expect(companion.cageNumber.value, 'C-1');
      expect(companion.notes.value, 'Notes');
      expect(companion.isDeleted.value, false);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
      );
      final companion = model.toCompanion();
      final after = DateTime.now();

      final updatedAt = companion.updatedAt.value!;
      expect(
        updatedAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(updatedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('encodes mutations to JSON', () {
      const model = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        mutations: ['blue', 'opaline'],
      );
      final companion = model.toCompanion();

      expect(companion.mutations.value, contains('blue'));
      expect(companion.mutations.value, contains('opaline'));
    });

    test('encodes genotypeInfo to JSON', () {
      const model = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        genotypeInfo: {'blue': 'visual'},
      );
      final companion = model.toCompanion();

      expect(companion.genotypeInfo.value, contains('blue'));
      expect(companion.genotypeInfo.value, contains('visual'));
    });

    test('null mutations encodes to null', () {
      const model = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
      );
      final companion = model.toCompanion();

      expect(companion.mutations.value, isNull);
    });
  });
}
