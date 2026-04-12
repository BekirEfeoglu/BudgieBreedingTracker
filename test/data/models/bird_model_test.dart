import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Bird model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final bird = createTestBird(
          id: 'bird-123',
          name: 'Mavi',
          gender: BirdGender.male,
          userId: 'user-1',
          status: BirdStatus.alive,
          species: Species.budgie,
          ringNumber: 'TR-2024-001',
          cageNumber: 'A-3',
          notes: 'Healthy bird',
          birthDate: DateTime(2023, 6, 15),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        final json = bird.toJson();
        final restored = Bird.fromJson(json);

        expect(restored.id, bird.id);
        expect(restored.name, bird.name);
        expect(restored.gender, bird.gender);
        expect(restored.userId, bird.userId);
        expect(restored.status, bird.status);
        expect(restored.species, bird.species);
        expect(restored.ringNumber, bird.ringNumber);
        expect(restored.cageNumber, bird.cageNumber);
        expect(restored.notes, bird.notes);
        expect(restored.isDeleted, bird.isDeleted);
      });

      test('handles null optional fields', () {
        final bird = createTestBird(
          id: 'bird-1',
          name: 'Test',
          gender: BirdGender.female,
          userId: 'user-1',
        );

        final json = bird.toJson();
        final restored = Bird.fromJson(json);

        expect(restored.ringNumber, isNull);
        expect(restored.photoUrl, isNull);
        expect(restored.fatherId, isNull);
        expect(restored.motherId, isNull);
        expect(restored.cageNumber, isNull);
        expect(restored.notes, isNull);
        expect(restored.birthDate, isNull);
        expect(restored.deathDate, isNull);
        expect(restored.soldDate, isNull);
      });

      test('defaults are correct', () {
        final bird = Bird.fromJson({
          'id': 'bird-1',
          'name': 'Test',
          'gender': 'male',
          'user_id': 'user-1',
        });

        expect(bird.status, BirdStatus.alive);
        expect(bird.species, Species.unknown);
        expect(bird.isDeleted, false);
      });

      test(
        'unknown species stays unknown instead of falling back to budgie',
        () {
          final bird = Bird.fromJson({
            'id': 'bird-1',
            'name': 'Test',
            'gender': 'nonexistent_gender',
            'user_id': 'user-1',
            'status': 'nonexistent_status',
            'species': 'nonexistent_species',
          });

          expect(bird.gender, BirdGender.unknown);
          expect(bird.status, BirdStatus.unknown);
          expect(bird.species, Species.unknown);
        },
      );

      test('toJson produces snake_case keys', () {
        final bird = createTestBird(
          userId: 'user-123',
          ringNumber: 'TR-001',
          fatherId: 'father-1',
        );
        final json = bird.toJson();

        expect(json.containsKey('user_id'), isTrue);
        expect(json.containsKey('ring_number'), isTrue);
        expect(json.containsKey('father_id'), isTrue);
        expect(json.containsKey('is_deleted'), isTrue);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed field', () {
        final bird = createTestBird(name: 'Original');
        final updated = bird.copyWith(name: 'Updated');

        expect(updated.name, 'Updated');
        expect(bird.name, 'Original'); // Original unchanged
      });

      test('preserves unchanged fields', () {
        final bird = createTestBird(
          id: 'bird-1',
          name: 'Mavi',
          gender: BirdGender.male,
          ringNumber: 'TR-001',
        );
        final updated = bird.copyWith(name: 'Yeni Ad');

        expect(updated.id, 'bird-1');
        expect(updated.gender, BirdGender.male);
        expect(updated.ringNumber, 'TR-001');
      });
    });

    group('equality', () {
      test('two birds with same fields are equal', () {
        final bird1 = createTestBird(id: 'bird-1', name: 'Mavi');
        final bird2 = createTestBird(id: 'bird-1', name: 'Mavi');

        expect(bird1, equals(bird2));
        expect(bird1.hashCode, equals(bird2.hashCode));
      });

      test('two birds with different fields are not equal', () {
        final bird1 = createTestBird(id: 'bird-1', name: 'Mavi');
        final bird2 = createTestBird(id: 'bird-2', name: 'Mavi');

        expect(bird1, isNot(equals(bird2)));
      });
    });
  });

  group('BirdX extension', () {
    group('isAlive', () {
      test('returns true for alive status', () {
        final bird = createTestBird(status: BirdStatus.alive);
        expect(bird.isAlive, isTrue);
      });

      test('returns false for dead status', () {
        final bird = createTestBird(status: BirdStatus.dead);
        expect(bird.isAlive, isFalse);
      });

      test('returns false for sold status', () {
        final bird = createTestBird(status: BirdStatus.sold);
        expect(bird.isAlive, isFalse);
      });
    });

    group('isMale / isFemale', () {
      test('isMale returns true for male', () {
        final bird = createTestBird(gender: BirdGender.male);
        expect(bird.isMale, isTrue);
        expect(bird.isFemale, isFalse);
      });

      test('isFemale returns true for female', () {
        final bird = createTestBird(gender: BirdGender.female);
        expect(bird.isFemale, isTrue);
        expect(bird.isMale, isFalse);
      });

      test('unknown is neither male nor female', () {
        final bird = createTestBird(gender: BirdGender.unknown);
        expect(bird.isMale, isFalse);
        expect(bird.isFemale, isFalse);
      });
    });

    group('age', () {
      test('returns null when birthDate is null', () {
        final bird = createTestBird(birthDate: null);
        expect(bird.age, isNull);
      });

      test('returns non-null when birthDate is set', () {
        final bird = createTestBird(
          birthDate: DateTime.now().subtract(const Duration(days: 365)),
        );
        expect(bird.age, isNotNull);
      });

      test('calculates years correctly', () {
        final twoYearsAgo = DateTime(
          DateTime.now().year - 2,
          DateTime.now().month,
          DateTime.now().day,
        );
        final bird = createTestBird(birthDate: twoYearsAgo);
        expect(bird.age!.years, 2);
      });
    });
  });

  group('BirdGender', () {
    test('toJson returns name', () {
      expect(BirdGender.male.toJson(), 'male');
      expect(BirdGender.female.toJson(), 'female');
      expect(BirdGender.unknown.toJson(), 'unknown');
    });

    test('fromJson parses correctly', () {
      expect(BirdGender.fromJson('male'), BirdGender.male);
      expect(BirdGender.fromJson('female'), BirdGender.female);
      expect(BirdGender.fromJson('unknown'), BirdGender.unknown);
    });
  });

  group('BirdStatus', () {
    test('toJson returns name', () {
      expect(BirdStatus.alive.toJson(), 'alive');
      expect(BirdStatus.dead.toJson(), 'dead');
      expect(BirdStatus.sold.toJson(), 'sold');
    });

    test('fromJson parses correctly', () {
      expect(BirdStatus.fromJson('alive'), BirdStatus.alive);
      expect(BirdStatus.fromJson('dead'), BirdStatus.dead);
      expect(BirdStatus.fromJson('sold'), BirdStatus.sold);
    });
  });

  group('Species', () {
    test('toJson returns name', () {
      expect(Species.budgie.toJson(), 'budgie');
      expect(Species.canary.toJson(), 'canary');
    });

    test('fromJson parses correctly', () {
      expect(Species.fromJson('budgie'), Species.budgie);
      expect(Species.fromJson('other'), Species.other);
    });
  });
}
