import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

void main() {
  group('calcChartInterval', () {
    test('returns 1 for values <= 5', () {
      expect(calcChartInterval(0), 1);
      expect(calcChartInterval(1), 1);
      expect(calcChartInterval(3), 1);
      expect(calcChartInterval(5), 1);
    });

    test('returns 2 for values 6-10', () {
      expect(calcChartInterval(6), 2);
      expect(calcChartInterval(8), 2);
      expect(calcChartInterval(10), 2);
    });

    test('returns 5 for values 11-25', () {
      expect(calcChartInterval(11), 5);
      expect(calcChartInterval(15), 5);
      expect(calcChartInterval(25), 5);
    });

    test('returns 10 for values 26-50', () {
      expect(calcChartInterval(26), 10);
      expect(calcChartInterval(50), 10);
    });

    test('returns 25 for values 51-100', () {
      expect(calcChartInterval(51), 25);
      expect(calcChartInterval(100), 25);
    });

    test('returns ceil(max/5) for values > 100', () {
      expect(calcChartInterval(200), 40);
      expect(calcChartInterval(500), 100);
      expect(calcChartInterval(1000), 200);
    });

    test('handles boundary values correctly', () {
      // Boundary: 5 → 1, 6 → 2
      expect(calcChartInterval(5), 1);
      expect(calcChartInterval(5.1), 2);

      // Boundary: 10 → 2, 11 → 5
      expect(calcChartInterval(10), 2);
      expect(calcChartInterval(10.1), 5);

      // Boundary: 25 → 5, 26 → 10
      expect(calcChartInterval(25), 5);
      expect(calcChartInterval(25.1), 10);

      // Boundary: 50 → 10, 51 → 25
      expect(calcChartInterval(50), 10);
      expect(calcChartInterval(50.1), 25);

      // Boundary: 100 → 25, 101 → ceil(101/5)=21
      expect(calcChartInterval(100), 25);
      expect(calcChartInterval(101), 21);
    });
  });

  group('calcChartMaxY', () {
    test('rounds up to next interval and adds one interval of headroom', () {
      // max=9, interval=2 → ceil(9/2)*2 + 2 = 10 + 2 = 12
      expect(calcChartMaxY(9, 2), 12);
    });

    test('aligns to interval when max is exact multiple', () {
      // max=10, interval=2 → ceil(10/2)*2 + 2 = 10 + 2 = 12
      expect(calcChartMaxY(10, 2), 12);
    });

    test('works with small values', () {
      // max=3, interval=1 → ceil(3/1)*1 + 1 = 3 + 1 = 4
      expect(calcChartMaxY(3, 1), 4);
    });

    test('works with large values', () {
      // max=87, interval=25 → ceil(87/25)*25 + 25 = 100 + 25 = 125
      expect(calcChartMaxY(87, 25), 125);
    });

    test('works with zero max', () {
      // max=0, interval=1 → ceil(0/1)*1 + 1 = 0 + 1 = 1
      expect(calcChartMaxY(0, 1), 1);
    });
  });
}
