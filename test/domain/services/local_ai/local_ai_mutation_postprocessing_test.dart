import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';

/// Simulates a model response and verifies post-processing behavior.
LocalAiMutationInsight _parse({
  required String mutation,
  String confidence = 'medium',
  String series = 'unknown',
  String pattern = 'unknown',
  String bodyColor = '',
  String wingPattern = '',
  String eyeColor = '',
  List<String> secondary = const [],
}) {
  return LocalAiMutationInsight.fromJson({
    'predicted_mutation': mutation,
    'confidence': confidence,
    'base_series': series,
    'pattern_family': pattern,
    'body_color': bodyColor,
    'wing_pattern': wingPattern,
    'eye_color': eyeColor,
    'rationale': 'test rationale',
    'secondary_possibilities': secondary,
  });
}

void main() {
  group('Mutation post-processing: all 45 labels recognized', () {
    // Non-red-eye mutations — should be preserved as-is
    const darkEyeMutations = [
      'normal_light_green',
      'normal_dark_green',
      'normal_olive',
      'normal_skyblue',
      'normal_cobalt',
      'normal_mauve',
      'spangle_green',
      'spangle_blue',
      'cinnamon_green',
      'cinnamon_blue',
      'opaline_green',
      'opaline_blue',
      'dominant_pied_green',
      'dominant_pied_blue',
      'recessive_pied_green',
      'recessive_pied_blue',
      'clearwing_green',
      'clearwing_blue',
      'greywing_green',
      'greywing_blue',
      'dilute_green',
      'dilute_blue',
      'clearbody_green',
      'clearbody_blue',
      'yellowface_blue',
      'violet_green',
      'violet_blue',
      'grey_green',
      'grey_blue',
      'opaline_cinnamon_green',
      'opaline_cinnamon_blue',
      'slate_blue',
      'dark_eyed_clear_green',
      'dark_eyed_clear_blue',
    ];

    for (final mutation in darkEyeMutations) {
      test('$mutation is preserved with dark eyes', () {
        final result = _parse(
          mutation: mutation,
          eyeColor: 'koyu/siyah',
          bodyColor: 'test',
          wingPattern: 'test',
        );
        expect(result.predictedMutation, mutation);
        expect(result.inoWarning, isEmpty);
      });
    }

    // Red-eye mutations — need red eye color to be preserved
    const redEyeMutations = [
      'lutino',
      'albino',
      'creamino',
      'fallow_green',
      'fallow_blue',
      'lacewing_green',
      'lacewing_blue',
      'texas_clearbody_green',
      'texas_clearbody_blue',
    ];

    for (final mutation in redEyeMutations) {
      test('$mutation is preserved with red eyes', () {
        final result = _parse(
          mutation: mutation,
          eyeColor: 'kırmızı/pembe',
          bodyColor: 'test',
          wingPattern: 'test',
        );
        expect(result.predictedMutation, mutation);
      });

      test('$mutation always gets low confidence', () {
        final result = _parse(
          mutation: mutation,
          confidence: 'high',
          eyeColor: 'kırmızı',
          bodyColor: 'test',
          wingPattern: 'test',
        );
        expect(result.confidence, LocalAiConfidence.low);
        expect(result.inoWarning, isNotEmpty);
      });
    }

    test('unknown is preserved when no series info', () {
      final result = _parse(mutation: 'unknown');
      expect(result.predictedMutation, 'unknown');
    });
  });

  group('Mutation post-processing: eye color gate corrections', () {
    test('albino + dark eyes → spangle_blue', () {
      final result = _parse(
        mutation: 'albino',
        series: 'blue',
        pattern: 'ino',
        eyeColor: 'koyu siyah',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
      );
      expect(result.predictedMutation, 'spangle_blue');
      expect(result.patternFamily, 'spangle');
    });

    test('lutino + dark eyes → spangle_green', () {
      final result = _parse(
        mutation: 'lutino',
        series: 'green',
        pattern: 'ino',
        eyeColor: 'siyah',
        bodyColor: 'sarı',
        wingPattern: 'sarı',
      );
      expect(result.predictedMutation, 'spangle_green');
    });

    test('creamino + dark eyes → spangle_blue', () {
      final result = _parse(
        mutation: 'creamino',
        series: 'blue',
        pattern: 'ino',
        eyeColor: 'koyu',
        bodyColor: 'krem',
        wingPattern: 'beyaz',
      );
      expect(result.predictedMutation, 'spangle_blue');
    });

    test('fallow_green + dark eyes → cinnamon_green', () {
      final result = _parse(
        mutation: 'fallow_green',
        series: 'green',
        pattern: 'fallow',
        eyeColor: 'siyah',
        bodyColor: 'yeşil',
        wingPattern: 'kahverengi',
      );
      expect(result.predictedMutation, 'cinnamon_green');
    });

    test('fallow_blue + dark eyes → cinnamon_blue', () {
      final result = _parse(
        mutation: 'fallow_blue',
        series: 'blue',
        pattern: 'fallow',
        eyeColor: 'koyu',
        bodyColor: 'mavi',
        wingPattern: 'kahverengi',
      );
      expect(result.predictedMutation, 'cinnamon_blue');
    });

    test('lacewing_green + dark eyes → cinnamon_green', () {
      final result = _parse(
        mutation: 'lacewing_green',
        series: 'green',
        pattern: 'lacewing',
        eyeColor: 'siyah',
        bodyColor: 'sarı',
        wingPattern: 'soluk kahverengi',
      );
      expect(result.predictedMutation, 'cinnamon_green');
    });

    test('lacewing_blue + dark eyes → cinnamon_blue', () {
      final result = _parse(
        mutation: 'lacewing_blue',
        series: 'blue',
        pattern: 'lacewing',
        eyeColor: 'koyu',
        bodyColor: 'beyaz',
        wingPattern: 'soluk kahverengi',
      );
      expect(result.predictedMutation, 'cinnamon_blue');
    });

    test('texas_clearbody_green + dark eyes → clearbody_green', () {
      final result = _parse(
        mutation: 'texas_clearbody_green',
        series: 'green',
        pattern: 'clearbody',
        eyeColor: 'siyah',
        bodyColor: 'açık yeşil',
        wingPattern: 'koyu',
      );
      expect(result.predictedMutation, 'clearbody_green');
    });

    test('texas_clearbody_blue + dark eyes → clearbody_blue', () {
      final result = _parse(
        mutation: 'texas_clearbody_blue',
        series: 'blue',
        pattern: 'clearbody',
        eyeColor: 'koyu',
        bodyColor: 'açık mavi',
        wingPattern: 'koyu',
      );
      expect(result.predictedMutation, 'clearbody_blue');
    });

    test('gate does not correct when eye_color is empty', () {
      final result = _parse(
        mutation: 'albino',
        series: 'albino',
        pattern: 'ino',
        bodyColor: 'beyaz',
      );
      expect(result.predictedMutation, 'albino');
    });

    test('gate prefers non-ino secondary over default correction', () {
      final result = _parse(
        mutation: 'albino',
        series: 'blue',
        pattern: 'ino',
        eyeColor: 'koyu',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
        secondary: ['dominant_pied_blue', 'dilute_blue'],
      );
      expect(result.predictedMutation, 'dominant_pied_blue');
    });
  });

  group('Mutation post-processing: unknown fallback inference', () {
    test('unknown + blue series + opaline pattern → opaline_blue', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        pattern: 'opaline',
        bodyColor: 'mavi',
        wingPattern: 'azaltılmış',
      );
      expect(result.predictedMutation, 'opaline_blue');
    });

    test('unknown + green series + cinnamon pattern → cinnamon_green', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'green',
        pattern: 'cinnamon',
        bodyColor: 'yeşil',
        wingPattern: 'kahverengi',
      );
      expect(result.predictedMutation, 'cinnamon_green');
    });

    test('unknown + blue series + spangle pattern → spangle_blue', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        pattern: 'spangle',
        bodyColor: 'mavi',
      );
      expect(result.predictedMutation, 'spangle_blue');
    });

    test('unknown + pale body + blue series + dark eyes → spangle_blue', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        bodyColor: 'beyaz',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'spangle_blue');
    });

    test('unknown + pale body + green series + dark eyes → spangle_green', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'green',
        bodyColor: 'açık sarı',
        eyeColor: 'siyah',
      );
      expect(result.predictedMutation, 'spangle_green');
    });

    test('unknown + pale body + blue series + red eyes → albino', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        bodyColor: 'beyaz',
        eyeColor: 'kırmızı',
      );
      expect(result.predictedMutation, 'albino');
    });

    test('unknown + pale body + green series + red eyes → lutino', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'green',
        bodyColor: 'soluk sarı',
        eyeColor: 'pembe',
      );
      expect(result.predictedMutation, 'lutino');
    });

    test('unknown + blue series + normal pattern → normal_skyblue fallback', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah çizgili',
      );
      // 'normal_blue' is not in signature, so falls to series fallback
      expect(result.predictedMutation, 'normal_skyblue');
    });

    test('unknown + green series + no other info → normal_light_green', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'green',
        bodyColor: 'yeşil',
      );
      expect(result.predictedMutation, 'normal_light_green');
    });

    test('unknown + secondary available → uses secondary', () {
      final result = _parse(
        mutation: 'unknown',
        series: 'blue',
        secondary: ['greywing_blue', 'dilute_blue'],
      );
      expect(result.predictedMutation, 'greywing_blue');
    });

    test('unknown + no series → stays unknown', () {
      final result = _parse(mutation: 'unknown');
      expect(result.predictedMutation, 'unknown');
      expect(result.confidence, LocalAiConfidence.low);
    });
  });

  group('Mutation post-processing: overlay mutation consistency', () {
    test('yellowface_blue accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'yellowface_blue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'kobalt mavi',
        wingPattern: 'normal siyah çizgili',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'yellowface_blue');
      // Should not be forced to low confidence due to pattern mismatch
      expect(result.confidence, isNot(LocalAiConfidence.low));
    });

    test('grey_green accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'grey_green',
        series: 'green',
        pattern: 'normal',
        bodyColor: 'gri-yeşil',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'grey_green');
    });

    test('grey_blue accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'grey_blue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'gri',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'grey_blue');
    });

    test('violet_green accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'violet_green',
        series: 'green',
        pattern: 'normal',
        bodyColor: 'koyu yeşil',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'violet_green');
    });

    test('violet_blue accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'violet_blue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mor-mavi',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'violet_blue');
    });

    test('slate_blue accepts normal pattern_family', () {
      final result = _parse(
        mutation: 'slate_blue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'koyu gri-mavi',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.predictedMutation, 'slate_blue');
    });
  });

  group('Mutation post-processing: confidence rules', () {
    test('unknown mutation → always low', () {
      final result = _parse(mutation: 'unknown', confidence: 'high');
      expect(result.confidence, LocalAiConfidence.low);
    });

    test('inconsistent mutation/series → low', () {
      // spangle_green claims blue series — inconsistent
      final result = _parse(
        mutation: 'spangle_green',
        series: 'blue',
        pattern: 'spangle',
        bodyColor: 'mavi',
        wingPattern: 'ters desen',
        eyeColor: 'koyu',
      );
      expect(result.confidence, LocalAiConfidence.low);
    });

    test('only 1 evidence item → low', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        confidence: 'high',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
      );
      expect(result.confidence, LocalAiConfidence.low);
    });

    test('2 evidence items + high raw → medium', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        confidence: 'high',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah çizgili',
      );
      expect(result.confidence, LocalAiConfidence.medium);
    });

    test('3 evidence items + high raw → high', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        confidence: 'high',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah çizgili',
        eyeColor: 'koyu',
      );
      expect(result.confidence, LocalAiConfidence.high);
    });

    test('3 evidence items + medium raw → medium', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        confidence: 'medium',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
      );
      expect(result.confidence, LocalAiConfidence.medium);
    });
  });

  group('Mutation post-processing: secondary suggestions', () {
    test('ino prediction adds spangle and pied alternatives', () {
      final result = _parse(
        mutation: 'albino',
        series: 'blue',
        pattern: 'ino',
        eyeColor: 'kırmızı',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
      );
      expect(result.secondaryPossibilities, contains('spangle_blue'));
      expect(result.secondaryPossibilities, contains('dominant_pied_blue'));
    });

    test('lutino adds green alternatives', () {
      final result = _parse(
        mutation: 'lutino',
        series: 'green',
        pattern: 'ino',
        eyeColor: 'kırmızı',
        bodyColor: 'sarı',
        wingPattern: 'sarı',
      );
      expect(result.secondaryPossibilities, contains('spangle_green'));
    });

    test('secondary list max 3 items', () {
      final result = _parse(
        mutation: 'albino',
        series: 'blue',
        pattern: 'ino',
        eyeColor: 'kırmızı',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
        secondary: ['dilute_blue', 'greywing_blue', 'clearwing_blue', 'dominant_pied_blue'],
      );
      expect(result.secondaryPossibilities.length, lessThanOrEqualTo(3));
    });

    test('inconsistent secondary items are filtered', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
        // spangle_green is green series, inconsistent with blue base
        secondary: ['spangle_green', 'normal_cobalt'],
      );
      expect(result.secondaryPossibilities, isNot(contains('spangle_green')));
      expect(result.secondaryPossibilities, contains('normal_cobalt'));
    });

    test('unknown secondary items are excluded', () {
      final result = _parse(
        mutation: 'normal_skyblue',
        series: 'blue',
        pattern: 'normal',
        bodyColor: 'mavi',
        wingPattern: 'siyah',
        eyeColor: 'koyu',
        secondary: ['unknown', 'normal_cobalt'],
      );
      expect(result.secondaryPossibilities, isNot(contains('unknown')));
    });
  });

  group('Mutation post-processing: inoWarning text', () {
    test('non-ino mutations have empty warning', () {
      final result = _parse(
        mutation: 'normal_light_green',
        series: 'green',
        pattern: 'normal',
        eyeColor: 'koyu',
        bodyColor: 'yeşil',
        wingPattern: 'siyah',
      );
      expect(result.inoWarning, isEmpty);
    });

    test('all red-eye mutations have non-empty warning', () {
      const redEyeMutations = [
        'lutino', 'albino', 'creamino',
        'fallow_green', 'fallow_blue',
        'lacewing_green', 'lacewing_blue',
        'texas_clearbody_green', 'texas_clearbody_blue',
      ];

      for (final mutation in redEyeMutations) {
        final result = _parse(
          mutation: mutation,
          eyeColor: 'kırmızı',
          bodyColor: 'test',
          wingPattern: 'test',
        );
        expect(
          result.inoWarning,
          isNotEmpty,
          reason: '$mutation should have inoWarning',
        );
      }
    });
  });

  group('Mutation post-processing: combo mutations', () {
    test('opaline_cinnamon_green is consistent with opaline OR cinnamon', () {
      // Model might report pattern as opaline
      final result1 = _parse(
        mutation: 'opaline_cinnamon_green',
        series: 'green',
        pattern: 'opaline',
        bodyColor: 'yeşil',
        wingPattern: 'kahverengi',
        eyeColor: 'koyu',
      );
      expect(result1.predictedMutation, 'opaline_cinnamon_green');

      // Model might report pattern as cinnamon
      final result2 = _parse(
        mutation: 'opaline_cinnamon_green',
        series: 'green',
        pattern: 'cinnamon',
        bodyColor: 'yeşil',
        wingPattern: 'kahverengi',
        eyeColor: 'koyu',
      );
      expect(result2.predictedMutation, 'opaline_cinnamon_green');
    });

    test('dark_eyed_clear_blue is consistent with spangle OR pied', () {
      final result1 = _parse(
        mutation: 'dark_eyed_clear_blue',
        series: 'blue',
        pattern: 'spangle',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
        eyeColor: 'koyu',
      );
      expect(result1.predictedMutation, 'dark_eyed_clear_blue');

      final result2 = _parse(
        mutation: 'dark_eyed_clear_blue',
        series: 'blue',
        pattern: 'pied',
        bodyColor: 'beyaz',
        wingPattern: 'beyaz',
        eyeColor: 'koyu',
      );
      expect(result2.predictedMutation, 'dark_eyed_clear_blue');
    });
  });
}
