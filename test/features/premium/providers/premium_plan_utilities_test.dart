import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

void main() {
  group('PremiumPlan.fromProductId', () {
    test('maps monthly variants', () {
      expect(PremiumPlan.fromProductId('premium_monthly'), PremiumPlan.monthly);
      expect(
        PremiumPlan.fromProductId('budgie_month_plan'),
        PremiumPlan.monthly,
      );
      expect(PremiumPlan.fromProductId('premium_1_month'), PremiumPlan.monthly);
      expect(
        PremiumPlan.fromProductId('budgie_1month_plan'),
        PremiumPlan.monthly,
      );
    });

    test('maps semi-annual variants', () {
      expect(
        PremiumPlan.fromProductId('premium_semi_annual'),
        PremiumPlan.semiAnnual,
      );
      expect(
        PremiumPlan.fromProductId('budgie_semiannual_plan'),
        PremiumPlan.semiAnnual,
      );
      expect(
        PremiumPlan.fromProductId('budgie_premium:semi-annual'),
        PremiumPlan.semiAnnual,
      );
      expect(
        PremiumPlan.fromProductId('premium_6_month'),
        PremiumPlan.semiAnnual,
      );
      expect(
        PremiumPlan.fromProductId('budgie_6month_plan'),
        PremiumPlan.semiAnnual,
      );
      expect(
        PremiumPlan.fromProductId('budgie_six-month_plan'),
        PremiumPlan.semiAnnual,
      );
    });

    test('maps yearly/annual variants', () {
      expect(PremiumPlan.fromProductId('premium_yearly'), PremiumPlan.yearly);
      expect(
        PremiumPlan.fromProductId('budgie_annual_plan'),
        PremiumPlan.yearly,
      );
      expect(PremiumPlan.fromProductId('premium_year'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('ANNUAL_PLAN'), PremiumPlan.yearly);
    });

    test('maps lifetime variants', () {
      expect(
        PremiumPlan.fromProductId('premium_lifetime'),
        PremiumPlan.lifetime,
      );
      expect(
        PremiumPlan.fromProductId('budgie_life_time_plan'),
        PremiumPlan.lifetime,
      );
      expect(
        PremiumPlan.fromProductId('premium_one_time'),
        PremiumPlan.lifetime,
      );
      expect(
        PremiumPlan.fromProductId('budgie_onetime_plan'),
        PremiumPlan.lifetime,
      );
    });

    test('returns null for unrecognized product IDs', () {
      expect(PremiumPlan.fromProductId('unknown_plan'), isNull);
      expect(PremiumPlan.fromProductId('premium_weekly'), isNull);
      expect(PremiumPlan.fromProductId(''), isNull);
    });

    test('is case-insensitive', () {
      expect(PremiumPlan.fromProductId('MONTHLY'), PremiumPlan.monthly);
      expect(PremiumPlan.fromProductId('SEMI_ANNUAL'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('SEMI-ANNUAL'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('YEARLY'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('6_MONTH'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('LIFETIME'), PremiumPlan.lifetime);
    });
  });

  group('PremiumPurchaseIssue', () {
    test('has all expected values', () {
      expect(
        PremiumPurchaseIssue.values,
        containsAll([
          PremiumPurchaseIssue.missingApiKey,
          PremiumPurchaseIssue.offeringsUnavailable,
          PremiumPurchaseIssue.iosDebugStoreKitRequired,
        ]),
      );
    });
  });
}
