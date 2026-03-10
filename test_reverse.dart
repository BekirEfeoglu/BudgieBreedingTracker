import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  const calculator = ReverseCalculator();
  // Target: Blue + Ino = Albino
  final results = calculator.calculateParents({'blue', 'ino'});

  if (results.isEmpty) {
    throw StateError('No reverse-calculation parent combinations found.');
  }
}
