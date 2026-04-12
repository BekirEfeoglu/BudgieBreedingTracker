import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Supabase extensions', () {
    group('BirdSupabase.toSupabase()', () {
      test('strips created_at and updated_at', () {
        final bird = createTestBird(
          id: 'bird-1',
          name: 'Mavi',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        final json = bird.toSupabase();

        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
        expect(json['id'], 'bird-1');
        expect(json['name'], 'Mavi');
      });

      test('preserves all other fields', () {
        final bird = createTestBird(
          id: 'bird-1',
          name: 'Mavi',
          userId: 'user-1',
          ringNumber: 'TR-001',
        );

        final json = bird.toSupabase();

        expect(json['id'], 'bird-1');
        expect(json['name'], 'Mavi');
        expect(json['user_id'], 'user-1');
        expect(json['ring_number'], 'TR-001');
      });
    });

    group('EggSupabase.toSupabase()', () {
      test('strips timestamp fields', () {
        final egg = Egg(
          id: 'egg-1',
          layDate: DateTime(2024, 1, 10),
          userId: 'user-1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        final json = egg.toSupabase();

        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
        expect(json['id'], 'egg-1');
      });
    });

    group('BreedingPairSupabase.toSupabase()', () {
      test('strips timestamp fields', () {
        final pair = BreedingPair(
          id: 'bp-1',
          maleId: 'bird-m',
          femaleId: 'bird-f',
          userId: 'user-1',
          status: BreedingStatus.active,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        final json = pair.toSupabase();

        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
        expect(json['id'], 'bp-1');
      });
    });

    group('NestSupabase.toSupabase()', () {
      test('strips timestamp fields', () {
        final nest = Nest(
          id: 'nest-1',
          userId: 'user-1',
          name: 'Nest A',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 6, 1),
        );

        final json = nest.toSupabase();

        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
        expect(json['id'], 'nest-1');
      });
    });

    group('_stripServerFields', () {
      test('does not affect non-timestamp fields', () {
        final bird = createTestBird(
          id: 'bird-1',
          name: 'Test',
          userId: 'user-1',
        );

        final json = bird.toSupabase();

        expect(json['id'], isNotNull);
        expect(json['name'], isNotNull);
        expect(json['user_id'], isNotNull);
      });
    });
  });
}
