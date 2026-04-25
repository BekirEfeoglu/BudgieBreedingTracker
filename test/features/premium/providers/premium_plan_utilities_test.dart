import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

void main() {
  group('PremiumPlan.fromProductId', () {
    test('maps semi-annual variants', () {
      expect(PremiumPlan.fromProductId('premium_semi_annual'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('budgie_semiannual_plan'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('premium_6_month'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('budgie_6month_plan'), PremiumPlan.semiAnnual);
    });

    test('maps yearly/annual variants', () {
      expect(PremiumPlan.fromProductId('premium_yearly'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('budgie_annual_plan'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('premium_year'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('ANNUAL_PLAN'), PremiumPlan.yearly);
    });

    test('returns null for unrecognized product IDs', () {
      expect(PremiumPlan.fromProductId('unknown_plan'), isNull);
      expect(PremiumPlan.fromProductId('premium_weekly'), isNull);
      expect(PremiumPlan.fromProductId(''), isNull);
    });

    test('is case-insensitive', () {
      expect(PremiumPlan.fromProductId('SEMI_ANNUAL'), PremiumPlan.semiAnnual);
      expect(PremiumPlan.fromProductId('YEARLY'), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId('6_MONTH'), PremiumPlan.semiAnnual);
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
