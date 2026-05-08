import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/widgets/eggs/egg_summary_row.dart'
    as core;
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

/// Data-bound adapter for the model-free core egg summary row.
class EggSummaryRow extends StatelessWidget {
  final List<Egg> eggs;

  const EggSummaryRow({super.key, required this.eggs});

  @override
  Widget build(BuildContext context) {
    return core.EggSummaryRow(
      statuses: eggs.map((egg) => egg.status).toList(growable: false),
    );
  }
}
