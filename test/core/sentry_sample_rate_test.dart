import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sentryTracesSampleRateFor', () {
    test(
      'should map sentry environment to budgeted trace sample rate',
      () {
        expect(sentryTracesSampleRateFor('development'), 1.0);
        expect(sentryTracesSampleRateFor('staging'), 0.5);
        expect(sentryTracesSampleRateFor('production'), 0.1);
        expect(
          sentryTracesSampleRateFor('anything-else'),
          0.1,
        ); // fail-safe: cheapest rate
      },
    );
  });
}
