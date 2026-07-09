import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

class HealthRecordAnimalSelector extends StatelessWidget {
  final String? selectedBirdId;
  final String? selectedChickId;
  final List<Bird> birds;
  final List<Chick> chicks;
  final bool isLoading;
  final ValueChanged<String?> onBirdChanged;
  final ValueChanged<String?> onChickChanged;

  static const _birdPrefix = 'bird:';
  static const _chickPrefix = 'chick:';

  const HealthRecordAnimalSelector({
    super.key,
    required this.selectedBirdId,
    required this.selectedChickId,
    required this.birds,
    required this.chicks,
    required this.isLoading,
    required this.onBirdChanged,
    required this.onChickChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && birds.isEmpty && chicks.isEmpty) {
      return const LinearProgressIndicator();
    }

    final theme = Theme.of(context);
    final sortedBirds = List<Bird>.from(birds)
      ..sort((a, b) => a.name.compareTo(b.name));
    final sortedChicks =
        chicks
            .where((c) => c.birdId == null) // Exclude promoted-to-bird chicks
            .toList()
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    final rawSelectedValue = selectedChickId != null
        ? '$_chickPrefix$selectedChickId'
        : selectedBirdId != null
        ? '$_birdPrefix$selectedBirdId'
        : null;
    // The persisted target may no longer be among the dropdown items — a chick
    // linked to a health record can later be promoted to a bird (filtered out
    // above), or a linked bird can be hard-deleted. DropdownButtonFormField
    // asserts the value matches exactly one item, so coerce an orphaned value
    // to null (the record's real chickId/birdId is held in separate screen
    // state and is preserved on save unless the user changes the selection).
    final validValues = <String>{
      for (final b in sortedBirds) '$_birdPrefix${b.id}',
      for (final c in sortedChicks) '$_chickPrefix${c.id}',
    };
    final selectedValue =
        (rawSelectedValue != null && validValues.contains(rawSelectedValue))
        ? rawSelectedValue
        : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: 'health_records.select_animal'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const AppIcon(AppIcons.bird),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'health_records.no_animal'.tr(),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (sortedBirds.isNotEmpty) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: '__header_birds__',
            child: Semantics(
              header: true,
              child: Text(
                '— ${'nav.birds'.tr()} —',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          ...sortedBirds.map(
            (bird) => DropdownMenuItem<String>(
              value: '$_birdPrefix${bird.id}',
              child: Text(
                bird.ringNumber != null
                    ? '${bird.name} (${bird.ringNumber})'
                    : bird.name,
              ),
            ),
          ),
        ],
        if (sortedChicks.isNotEmpty) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: '__header_chicks__',
            child: Semantics(
              header: true,
              child: Text(
                '— ${'nav.chicks'.tr()} —',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          ...sortedChicks.map((chick) {
            final name =
                chick.name ??
                '${'chicks.chick_label'.tr()} #${chick.ringNumber ?? chick.id.substring(0, 6)}';
            return DropdownMenuItem<String>(
              value: '$_chickPrefix${chick.id}',
              child: Text(
                chick.ringNumber != null && chick.name != null
                    ? '$name (${chick.ringNumber})'
                    : name,
              ),
            );
          }),
        ],
      ],
      onChanged: _handleChanged,
      isExpanded: true,
    );
  }

  void _handleChanged(String? value) {
    if (value == null) {
      onBirdChanged(null);
      onChickChanged(null);
      return;
    }
    if (value.startsWith(_birdPrefix)) {
      onBirdChanged(value.substring(_birdPrefix.length));
      onChickChanged(null);
      return;
    }
    if (value.startsWith(_chickPrefix)) {
      onBirdChanged(null);
      onChickChanged(value.substring(_chickPrefix.length));
    }
  }
}
