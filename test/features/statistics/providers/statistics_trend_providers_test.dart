import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

void main() {
  group('TrendStats', () {
    test('default values are zero', () {
      const stats = TrendStats();
      expect(stats.birdsTrend, 0.0);
      expect(stats.breedingsTrend, 0.0);
      expect(stats.eggsTrend, 0.0);
      expect(stats.fertilityTrend, 0.0);
      expect(stats.survivalTrend, 0.0);
    });

    test('accepts custom values', () {
      const stats = TrendStats(
        birdsTrend: 25.0,
        breedingsTrend: -10.0,
        eggsTrend: 50.0,
        fertilityTrend: 5.5,
        survivalTrend: -2.3,
      );
      expect(stats.birdsTrend, 25.0);
      expect(stats.breedingsTrend, -10.0);
      expect(stats.eggsTrend, 50.0);
      expect(stats.fertilityTrend, 5.5);
      expect(stats.survivalTrend, -2.3);
    });
  });

  group('QuickInsight', () {
    test('construction with positive sentiment', () {
      const insight = QuickInsight(
        text: 'Egg production increased',
        sentiment: InsightSentiment.positive,
      );
      expect(insight.text, 'Egg production increased');
      expect(insight.sentiment, InsightSentiment.positive);
    });

    test('construction with negative sentiment', () {
      const insight = QuickInsight(
        text: 'Survival rate decreased',
        sentiment: InsightSentiment.negative,
      );
      expect(insight.sentiment, InsightSentiment.negative);
    });

    test('construction with neutral sentiment', () {
      const insight = QuickInsight(
        text: 'No significant change',
        sentiment: InsightSentiment.neutral,
      );
      expect(insight.sentiment, InsightSentiment.neutral);
    });
  });

  group('InsightSentiment', () {
    test('has three values', () {
      expect(InsightSentiment.values, hasLength(3));
    });

    test('contains all expected values', () {
      expect(InsightSentiment.values, contains(InsightSentiment.positive));
      expect(InsightSentiment.values, contains(InsightSentiment.negative));
      expect(InsightSentiment.values, contains(InsightSentiment.neutral));
    });
  });
}
