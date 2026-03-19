import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

/// A dropdown selector for choosing a clutch from a list.
class EggClutchSelector extends StatelessWidget {
  final List<Clutch> clutches;
  final String? selectedClutchId;
  final ValueChanged<String?> onChanged;

  const EggClutchSelector({
    super.key,
    required this.clutches,
    this.selectedClutchId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validSelectedId =
        selectedClutchId != null && clutches.any((c) => c.id == selectedClutchId)
            ? selectedClutchId
            : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(validSelectedId),
      initialValue: validSelectedId,
      decoration: InputDecoration(
        labelText: 'eggs.select_clutch'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const AppIcon(AppIcons.egg),
      ),
      items: clutches.map((clutch) {
        return DropdownMenuItem<String>(
          value: clutch.id,
          child: Text(
            clutch.name ?? clutch.id.substring(0, 8),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
