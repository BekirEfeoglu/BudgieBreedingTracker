import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

/// Dropdown selector for choosing a parent bird (father or mother).
class BirdParentSelector extends ConsumerWidget {
  static const _maxDisplayCandidates = 50;

  final String label;
  final Widget icon;
  final String? selectedId;
  final String? excludeId;
  final Species? speciesFilter;
  final BirdGender genderFilter;
  final ValueChanged<String?> onChanged;

  const BirdParentSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedId,
    required this.excludeId,
    this.speciesFilter,
    required this.genderFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));

    return birdsAsync.when(
      loading: () => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: icon,
          ),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (_, __) => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: icon,
          ),
        ),
        items: const [],
        onChanged: null,
      ),
      data: (birds) {
        final candidates =
            birds
                .where((b) => b.gender == genderFilter)
                .where((b) => b.id != excludeId)
                .where(
                  (b) => speciesFilter == null || b.species == speciesFilter,
                )
                .where((b) => b.status == BirdStatus.alive)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        final displayCandidates = candidates
            .take(_maxDisplayCandidates)
            .toList();

        Bird? selectedBird;
        if (selectedId != null) {
          for (final bird in birds) {
            if (bird.id == selectedId &&
                bird.id != excludeId &&
                bird.gender == genderFilter &&
                (speciesFilter == null || bird.species == speciesFilter)) {
              selectedBird = bird;
              break;
            }
          }
        }

        if (selectedBird != null &&
            !displayCandidates.any((bird) => bird.id == selectedBird?.id)) {
          displayCandidates.insert(0, selectedBird);
        }

        final effectiveSelectedId =
            selectedId != null &&
                displayCandidates.any((bird) => bird.id == selectedId)
            ? selectedId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: effectiveSelectedId,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: icon,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'birds.no_parent'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...displayCandidates.map(
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
          onChanged: onChanged,
          isExpanded: true,
        );
      },
    );
  }
}

class BirdFormSectionHeader extends StatelessWidget {
  final String title;

  const BirdFormSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
