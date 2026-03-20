import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

class HealthRecordAnimalSelector extends StatelessWidget {
  final String? selectedId;
  final List<Bird> birds;
  final List<Chick> chicks;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  const HealthRecordAnimalSelector({
    super.key,
    required this.selectedId,
    required this.birds,
    required this.chicks,
    required this.isLoading,
    required this.onChanged,
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

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          ...sortedBirds.map(
            (bird) => DropdownMenuItem<String>(
              value: bird.id,
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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
              value: chick.id,
              child: Text(
                chick.ringNumber != null && chick.name != null
                    ? '$name (${chick.ringNumber})'
                    : name,
              ),
            );
          }),
        ],
      ],
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
