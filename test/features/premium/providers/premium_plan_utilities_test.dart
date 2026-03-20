import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

void main() {
  group('PremiumPlan.fromProductId', () {
    test('maps monthly variants', () {
      expect(PremiumPlan.fromProductId('premium_monthly'), PremiumPlan.monthly);
      expect(PremiumPlan.fromProductId('budgie_month_plan'), PremiumPlan.monthly);
      expect(PremiumPlan.fromProductId('PREMIUM_MONTHLY'), PremiumPlan.monthly);
    });

    test('maps yearly/annual variants', () {
      expect(PremiumPlan.fromProductId('premium_yearly'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('budgie_annual_plan'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('premium_year'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('ANNUAL_PLAN'), PremiumPlan.yearly);
    });

    test('maps lifetime variants', () {
      expect(PremiumPlan.fromProductId('premium_lifetime'), PremiumPlan.lifetime);
      expect(PremiumPlan.fromProductId('budgie_life_plan'), PremiumPlan.lifetime);
      expect(PremiumPlan.fromProductId('LIFETIME_ACCESS'), PremiumPlan.lifetime);
    });

    test('returns null for unrecognized product IDs', () {
      expect(PremiumPlan.fromProductId('unknown_plan'), isNull);
      expect(PremiumPlan.fromProductId('premium_weekly'), isNull);
      expect(PremiumPlan.fromProductId(''), isNull);
    });

    test('is case-insensitive', () {
      expect(PremiumPlan.fromProductId('Monthly'), PremiumPlan.monthly);
      expect(PremiumPlan.fromProductId('YEARLY'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('Lifetime'), PremiumPlan.lifetime);
    });
  });

  group('PremiumPurchaseIssue', () {
    test('has all expected values', () {
      expect(PremiumPurchaseIssue.values, containsAll([
        PremiumPurchaseIssue.missingApiKey,
        PremiumPurchaseIssue.offeringsUnavailable,
        PremiumPurchaseIssue.iosDebugStoreKitRequired,
      ]));
    });
  });
}
