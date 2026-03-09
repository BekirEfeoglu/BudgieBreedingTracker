import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

void main() {
  group('GuideCategory', () {
    test('every value has a non-empty labelKey', () {
      for (final category in GuideCategory.values) {
        expect(
          category.labelKey,
          isNotEmpty,
          reason: '${category.name}.labelKey is empty',
        );
      }
    });

    test('every value has a non-empty iconAsset', () {
      for (final category in GuideCategory.values) {
        expect(
          category.iconAsset,
          isNotEmpty,
          reason: '${category.name}.iconAsset is empty',
        );
      }
    });

    test('all values appear in the enum', () {
      expect(
        GuideCategory.values,
        containsAll([
          GuideCategory.all,
          GuideCategory.gettingStarted,
          GuideCategory.birdManagement,
          GuideCategory.breedingProcess,
          GuideCategory.tools,
          GuideCategory.dataManagement,
          GuideCategory.accountSettings,
        ]),
      );
    });

    test('all category except "all" can be used as filter', () {
      final filterCategories = GuideCategory.values
          .where((c) => c != GuideCategory.all)
          .toList();
      expect(filterCategories, isNotEmpty);
      // Each non-all category has distinct name
      final names = filterCategories.map((c) => c.name).toSet();
      expect(names.length, filterCategories.length);
    });
  });

  group('GuideTopic', () {
    test('guideTopics contains exactly 15 topics', () {
      expect(guideTopics.length, 15);
    });

    test('every topic has a non-empty titleKey', () {
      for (final topic in guideTopics) {
        expect(
          topic.titleKey,
          isNotEmpty,
          reason: 'A topic has an empty titleKey',
        );
      }
    });

    test('every topic has a non-empty iconAsset', () {
      for (final topic in guideTopics) {
        expect(
          topic.iconAsset,
          isNotEmpty,
          reason: '${topic.titleKey} has empty iconAsset',
        );
      }
    });

    test('every topic has a non-null category', () {
      for (final topic in guideTopics) {
        expect(topic.category, isNotNull);
      }
    });

    test('every topic has at least one block', () {
      for (final topic in guideTopics) {
        expect(
          topic.blocks,
          isNotEmpty,
          reason: '${topic.titleKey} has no blocks',
        );
      }
    });

    test('topics span all non-all categories', () {
      final usedCategories = guideTopics.map((t) => t.category).toSet();
      expect(usedCategories, isNot(contains(GuideCategory.all)));
      expect(
        usedCategories,
        containsAll([
          GuideCategory.gettingStarted,
          GuideCategory.birdManagement,
          GuideCategory.breedingProcess,
          GuideCategory.tools,
          GuideCategory.dataManagement,
          GuideCategory.accountSettings,
        ]),
      );
    });
  });

  group('GuideBlock factory constructors', () {
    test('GuideBlock.text sets type to text', () {
      const block = GuideBlock.text('some.key');
      expect(block.type, GuideBlockType.text);
      expect(block.textKey, 'some.key');
      expect(block.stepsTitle, isNull);
      expect(block.stepKeys, isNull);
    });

    test('GuideBlock.tip sets type to tip', () {
      const block = GuideBlock.tip('tip.key');
      expect(block.type, GuideBlockType.tip);
      expect(block.textKey, 'tip.key');
    });

    test('GuideBlock.warning sets type to warning', () {
      const block = GuideBlock.warning('warn.key');
      expect(block.type, GuideBlockType.warning);
      expect(block.textKey, 'warn.key');
    });

    test('GuideBlock.premiumNote sets type to premiumNote', () {
      const block = GuideBlock.premiumNote('prem.key');
      expect(block.type, GuideBlockType.premiumNote);
      expect(block.textKey, 'prem.key');
    });

    test('GuideBlock.steps sets type to steps and has stepKeys', () {
      const block = GuideBlock.steps(
        stepsTitle: 'steps.title',
        stepKeys: ['s1', 's2', 's3'],
      );
      expect(block.type, GuideBlockType.steps);
      expect(block.stepsTitle, 'steps.title');
      expect(block.stepKeys, ['s1', 's2', 's3']);
      expect(block.textKey, isNull);
    });
  });

  group('GuideBlockType', () {
    test('enum has 5 values', () {
      expect(GuideBlockType.values.length, 5);
    });
  });
}
