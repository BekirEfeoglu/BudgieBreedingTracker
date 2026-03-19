import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  test('Reverse Calculator tests', () {
    const calculator = ReverseCalculator();
    final results = calculator.calculateParents({'blue', 'ino'});
    expect(results, isNotEmpty);
    expect(
      results.any((result) => result.maxProbability > 0),
      isTrue,
    );

    final resultsBlue = calculator.calculateParents({'blue'});
    expect(resultsBlue, isNotEmpty);
  });
}
