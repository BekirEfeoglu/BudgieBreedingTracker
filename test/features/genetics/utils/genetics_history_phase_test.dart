import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

import '../../../helpers/mocks.dart';

GeneticsHistory _historyFixture({
  String id = 'h1',
  Map<String, String>? fatherPhaseOverrides,
}) {
  return GeneticsHistory(
    id: id,
    userId: 'user-1',
    fatherGenotype: const {'ino': 'split', 'slate': 'split'},
    motherGenotype: const {},
    fatherPhaseOverrides: fatherPhaseOverrides,
    resultsJson: '[]',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_historyFixture());
  });

  group('GeneticsHistory.fatherPhaseOverrides — save path', () {
    late MockGeneticsHistoryDao dao;

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          geneticsHistoryDaoProvider.overrideWithValue(dao),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
    }

    setUp(() {
      dao = MockGeneticsHistoryDao();
      when(() => dao.insertItem(any())).thenAnswer((_) async {});
    });

    test(
      '(a) saving a father with a coupling override persists pairKey -> '
      "'coupling' on the history record",
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.split, 'slate': AlleleState.split},
        ).withPhaseOverride('ino', 'slate', LinkagePhase.coupling);
        container.read(motherGenotypeProvider.notifier).state =
            const ParentGenotype.empty(gender: BirdGender.female);

        await container.read(offspringResultsProvider.future);

        final ok = await container
            .read(geneticsHistorySaveProvider.notifier)
            .saveCurrentCalculation();
        expect(ok, isTrue);

        final captured =
            verify(() => dao.insertItem(captureAny())).captured.single
                as GeneticsHistory;
        expect(
          captured.fatherPhaseOverrides,
          {linkagePairKey('ino', 'slate'): 'coupling'},
        );
      },
    );

    test(
      'saving a father with no overrides persists a null map (not an empty '
      'one) so legacy readers still see "no field"',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual},
        );
        container.read(motherGenotypeProvider.notifier).state =
            const ParentGenotype.empty(gender: BirdGender.female);

        await container.read(offspringResultsProvider.future);

        final ok = await container
            .read(geneticsHistorySaveProvider.notifier)
            .saveCurrentCalculation();
        expect(ok, isTrue);

        final captured =
            verify(() => dao.insertItem(captureAny())).captured.single
                as GeneticsHistory;
        expect(captured.fatherPhaseOverrides, isNull);
      },
    );
  });

  group('parseStoredGenotype — fatherPhaseOverrides load path', () {
    test(
      '(b) restores phaseFor from a stored pairKey -> phase-name map',
      () {
        final stored = {linkagePairKey('ino', 'slate'): 'coupling'};

        final genotype = parseStoredGenotype(
          const {'ino': 'split', 'slate': 'split'},
          BirdGender.male,
          storedPhaseOverrides: stored,
        );

        expect(genotype.phaseFor('ino', 'slate'), LinkagePhase.coupling);
      },
    );

    test(
      '(c) legacy id in the stored pair key resolves to the canonical pair',
      () {
        // 'lutino' is a legacy id for 'ino' (MutationDatabase.resolveId).
        final stored = {'lutino|slate': 'repulsion'};

        final genotype = parseStoredGenotype(
          const {'lutino': 'split', 'slate': 'split'},
          BirdGender.male,
          storedPhaseOverrides: stored,
        );

        // The canonical (resolved) pair reads back the restored phase...
        expect(genotype.phaseFor('ino', 'slate'), LinkagePhase.repulsion);
        // ...and the raw legacy-id key is not what's stored internally.
        expect(
          genotype.phaseOverrides.containsKey('lutino|slate'),
          isFalse,
        );
        expect(
          genotype.phaseOverrides.containsKey(linkagePairKey('ino', 'slate')),
          isTrue,
        );
      },
    );

    test(
      '(d) null fatherPhaseOverrides yields empty overrides (auto)',
      () {
        final genotype = parseStoredGenotype(
          const {'ino': 'split', 'slate': 'split'},
          BirdGender.male,
        );

        expect(genotype.phaseOverrides, isEmpty);
        expect(genotype.phaseFor('ino', 'slate'), LinkagePhase.auto);
      },
    );

    test(
      '(d) absent (unset) fatherPhaseOverrides argument also yields empty '
      'overrides (auto) — matches legacy pre-feature history entries',
      () {
        final genotype = parseStoredGenotype(
          const {'ino': 'split', 'slate': 'split'},
          BirdGender.male,
          storedPhaseOverrides: null,
        );

        expect(genotype.phaseOverrides, isEmpty);
        expect(genotype.phaseFor('ino', 'slate'), LinkagePhase.auto);
      },
    );

    test('malformed pair keys (not exactly two halves) are skipped', () {
      final stored = {
        'not-a-pair-key': 'coupling',
        'a|b|c': 'coupling',
        linkagePairKey('ino', 'slate'): 'repulsion',
      };

      final genotype = parseStoredGenotype(
        const {'ino': 'split', 'slate': 'split'},
        BirdGender.male,
        storedPhaseOverrides: stored,
      );

      expect(genotype.phaseOverrides.length, 1);
      expect(genotype.phaseFor('ino', 'slate'), LinkagePhase.repulsion);
    });
  });
}
