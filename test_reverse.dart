import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  final calculator = ReverseCalculator();
  // Target: Blue + Ino = Albino
  final results = calculator.calculateParents({'blue', 'ino'});

  print('Found \${results.length} possible parent combinations.');
  for (var i = 0; i < 5 && i < results.length; i++) {
    final r = results[i];
    print('Option \${i+1} : \${r.maxProbability * 100}%');
    print('  Father: \${r.father.mutations}');
    print('  Mother: \${r.mother.mutations}');
  }
}
