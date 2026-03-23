import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

void main() {
  group('GuideCategory', () {
    test('has exactly 6 values (all removed)', () {
      expect(GuideCategory.values.length, 6);
    });

    test('all categories have non-empty labelKey starting with '
        'user_guide.category_', () {
      for (final category in GuideCategory.values) {
        expect(
          category.labelKey,
          isNotEmpty,
          reason: '${category.name}.labelKey is empty',
        );
        expect(
          category.labelKey,
          startsWith('user_guide.category_'),
          reason:
              '${category.name}.labelKey does not start with '
              'user_guide.category_',
        );
      }
    });

    test('all categories have non-empty iconAsset', () {
      for (final category in GuideCategory.values) {
        expect(
          category.iconAsset,
          isNotEmpty,
          reason: '${category.name}.iconAsset is empty',
        );
      }
    });
  });

  group('GuideTopic', () {
    test('guideTopics has exactly 15 entries', () {
      expect(guideTopics.length, 15);
    });

    test('every topic has non-empty titleKey starting with '
        'user_guide.topics.', () {
      for (final topic in guideTopics) {
        expect(
          topic.titleKey,
          isNotEmpty,
          reason: 'A topic has an empty titleKey',
        );
        expect(
          topic.titleKey,
          startsWith('user_guide.topics.'),
          reason: '${topic.titleKey} does not start with user_guide.topics.',
        );
      }
    });

    test('every topic has non-empty subtitleKey starting with '
        'user_guide.topics.', () {
      for (final topic in guideTopics) {
        expect(
          topic.subtitleKey,
          isNotEmpty,
          reason: '${topic.titleKey} has empty subtitleKey',
        );
        expect(
          topic.subtitleKey,
          startsWith('user_guide.topics.'),
          reason:
              '${topic.titleKey} subtitleKey does not start with '
              'user_guide.topics.',
        );
      }
    });

    test('every topic has non-empty iconAsset', () {
      for (final topic in guideTopics) {
        expect(
          topic.iconAsset,
          isNotEmpty,
          reason: '${topic.titleKey} has empty iconAsset',
        );
      }
    });

    test('every topic has non-empty blocks list', () {
      for (final topic in guideTopics) {
        expect(
          topic.blocks,
          isNotEmpty,
          reason: '${topic.titleKey} has no blocks',
        );
      }
    });

    test('exactly 1 premium topic (genealogy_genetics)', () {
      final premiumTopics = guideTopics.where((t) => t.isPremium).toList();
      expect(premiumTopics.length, 1);
      expect(
        premiumTopics.first.titleKey,
        'user_guide.topics.genealogy_genetics.title',
      );
    });

    test('all relatedTopicIndices are valid (in range, no self-reference)', () {
      for (var i = 0; i < guideTopics.length; i++) {
        final topic = guideTopics[i];
        for (final relatedIndex in topic.relatedTopicIndices) {
          expect(
            relatedIndex,
            greaterThanOrEqualTo(0),
            reason:
                '${topic.titleKey} has negative relatedTopicIndex '
                '$relatedIndex',
          );
          expect(
            relatedIndex,
            lessThan(guideTopics.length),
            reason:
                '${topic.titleKey} has out-of-range relatedTopicIndex '
                '$relatedIndex',
          );
          expect(
            relatedIndex,
            isNot(equals(i)),
            reason: '${topic.titleKey} has self-reference at index $i',
          );
        }
      }
    });

    test('stepCount returns total step keys across all step blocks', () {
      // Registration topic (index 0) has 1 steps block with 4 steps
      final registration = guideTopics[0];
      expect(registration.stepCount, 4);

      // Dashboard topic (index 1) has no steps blocks
      final dashboard = guideTopics[1];
      expect(dashboard.stepCount, 0);
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
    test('has 5 values', () {
      expect(GuideBlockType.values.length, 5);
    });
  });
}
