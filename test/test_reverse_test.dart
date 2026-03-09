import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  test('Reverse Calculator tests', () {
    final calculator = ReverseCalculator();
    final results = calculator.calculateParents({'blue', 'ino'});

    print('Found ${results.length} possible parent combinations.');
    for (var i = 0; i < 5 && i < results.length; i++) {
      final r = results[i];
      print('Option ${i + 1} : ${r.maxProbability * 100}%');
      print('  Father: ${r.father.mutations}');
      print('  Mother: ${r.mother.mutations}');
    }

    final resultsBlue = calculator.calculateParents({'blue'});
    print('Blue only: ${resultsBlue.length}');
  });
}
