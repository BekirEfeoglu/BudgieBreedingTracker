import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

/// Egg summary section of the breeding card.
class BreedingCardEggs extends StatelessWidget {
  final List<Egg> eggs;

  const BreedingCardEggs({super.key, required this.eggs});

  @override
  Widget build(BuildContext context) {
    return EggSummaryRow(eggs: eggs);
  }
}
