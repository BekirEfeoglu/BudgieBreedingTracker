import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/widgets/eggs/egg_list_item.dart'
    as core;
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_conflict_badge.dart';

/// Data-bound adapter for the model-free core egg list item.
class EggListItem extends StatelessWidget {
  final Egg egg;
  final DateFormat? dateFormatter;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;
  final VoidCallback? onDelete;

  const EggListItem({
    super.key,
    required this.egg,
    this.dateFormatter,
    this.onTap,
    this.onStatusUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return core.EggListItem(
      eggNumber: egg.eggNumber,
      status: egg.status,
      layDate: egg.layDate,
      incubationDays: egg.incubationDays,
      dateFormatter: dateFormatter,
      trailingBadge: RecordSyncConflictBadge(
        tableName: SupabaseConstants.eggsTable,
        recordId: egg.id,
      ),
      onTap: onTap,
      onStatusUpdate: onStatusUpdate,
      onDelete: onDelete,
    );
  }
}
