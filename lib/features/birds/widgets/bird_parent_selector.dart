import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';

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
    // Drift-side filtered stream: pre-filtered to (alive, gender, species,
    // !=excludeId). Cuts memory pressure for users with thousands of birds
    // and removes the in-Dart filter pipeline that previously ran on every
    // dropdown rebuild.
    final candidatesAsync = ref.watch(
      birdParentCandidatesProvider((
        userId: userId,
        gender: genderFilter,
        species: speciesFilter,
        excludeId: excludeId,
      )),
    );

    return candidatesAsync.when(
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
      data: (candidates) {
        final displayCandidates = candidates
            .take(_maxDisplayCandidates)
            .toList();

        // If the currently-selected bird isn't in the filtered window
        // (e.g. status changed to dead after selection, species was
        // changed, or it falls past the 50-candidate cap), look it up
        // through the per-bird stream provider so the dropdown can still
        // display its current value rather than silently flipping to
        // null. Using `birdByIdProvider(selectedId)` keeps the perf win:
        // only ONE extra row is subscribed instead of the full flock.
        Bird? selectedBird;
        if (selectedId != null &&
            !displayCandidates.any((b) => b.id == selectedId)) {
          final id = selectedId!;
          final fallback = ref.watch(birdByIdProvider(id)).value;
          if (fallback != null &&
              fallback.id != excludeId &&
              fallback.gender == genderFilter &&
              (speciesFilter == null || fallback.species == speciesFilter)) {
            selectedBird = fallback;
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
