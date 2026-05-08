import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/eggs/egg_status_update_sheet.dart'
    as core;
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';

/// Shows a bottom sheet for updating an egg's status.
///
/// Returns the selected status, or null if dismissed.
Future<EggStatus?> showEggStatusUpdateSheet(BuildContext context, Egg egg) {
  return core.showEggStatusUpdateSheet(
    context,
    currentStatus: egg.status,
    eggNumber: egg.eggNumber,
    transitions: IncubationCalculator.getValidStatusTransitions(egg.status),
  );
}
