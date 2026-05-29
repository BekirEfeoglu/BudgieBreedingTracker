import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/shared/widgets/genetics.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';

export 'bird_form_basic_info_section.dart';

/// Genetics section: optional detailed mutation and allele-state profile.
class BirdFormGeneticsSection extends StatelessWidget {
  final Species species;
  final GeneticsMode geneticsMode;
  final BirdGender gender;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const BirdFormGeneticsSection({
    super.key,
    required this.species,
    required this.geneticsMode,
    required this.gender,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = ParentGenotype(
      mutations: Map<String, AlleleState>.from(genotype.mutations),
      gender: gender,
    );

    final helpKey = switch (geneticsMode) {
      GeneticsMode.full => 'birds.genetics_help_full',
      GeneticsMode.limited => 'birds.genetics_help_limited',
      GeneticsMode.none => 'birds.genetics_help_none',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('genetics.title'.tr()),
        if (geneticsMode == GeneticsMode.full)
          MutationSelector(
            label: 'genetics.individual_mutations'.tr(),
            icon: const AppIcon(AppIcons.dna),
            genotype: normalized,
            onGenotypeChanged: onGenotypeChanged,
          )
        else
          InfoCard(
            icon: const AppIcon(AppIcons.info),
            title: 'genetics.title'.tr(),
            subtitle: helpKey.tr(args: [speciesLabel(species)]),
          ),
      ],
    );
  }
}

/// Identity section: ring number, birth date, cage number.
///
/// Promoted from StatelessWidget → ConsumerStatefulWidget so the ring-number
/// field can run a debounced async uniqueness check while the user types,
/// instead of waiting for submit to surface the conflict (was: server-side
/// only via `_hasRingNumberConflict`, user types whole value + presses Save
/// before learning the value is taken).
class BirdFormIdentitySection extends ConsumerStatefulWidget {
  final TextEditingController ringController;
  final TextEditingController cageController;
  final DateTime? birthDate;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final DateFormat? dateFormatter;

  /// Bird ID currently being edited — passed to `hasRingNumber` so the
  /// own row doesn't count as a conflict against itself.
  final String? editBirdId;

  const BirdFormIdentitySection({
    super.key,
    required this.ringController,
    required this.cageController,
    required this.birthDate,
    required this.onBirthDateChanged,
    this.dateFormatter,
    this.editBirdId,
  });

  @override
  ConsumerState<BirdFormIdentitySection> createState() =>
      _BirdFormIdentitySectionState();
}

class _BirdFormIdentitySectionState
    extends ConsumerState<BirdFormIdentitySection> {
  /// Monotonic request counter to discard stale results. Without this, a
  /// slow query for an earlier value could overwrite the result for a
  /// later value typed in between (providers.md race-condition pattern).
  int _requestId = 0;
  Timer? _debounce;
  String? _ringError;
  String? _lastCheckedValue;

  @override
  void initState() {
    super.initState();
    widget.ringController.addListener(_onRingChanged);
  }

  @override
  void dispose() {
    widget.ringController.removeListener(_onRingChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onRingChanged() {
    final value = widget.ringController.text.trim();
    if (value == _lastCheckedValue) return;
    // Empty ring numbers are allowed — clear any error and skip the check.
    if (value.isEmpty) {
      _debounce?.cancel();
      if (_ringError != null) {
        setState(() => _ringError = null);
      }
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _checkUnique(value);
    });
  }

  Future<void> _checkUnique(String value) async {
    final id = ++_requestId;
    final userId = ref.read(currentUserIdProvider);
    if (userId.isEmpty) return;
    try {
      final exists = await ref
          .read(birdRepositoryProvider)
          .hasRingNumber(userId, value, excludeId: widget.editBirdId);
      // Discard the result if a newer keystroke superseded it OR the widget
      // was disposed while the await was in flight.
      if (id != _requestId || !mounted) return;
      setState(() {
        _lastCheckedValue = value;
        // Reuses the existing l10n key already shown on submit-time
        // server check (`_hasRingNumberConflict`). Same string, earlier
        // surface — the user sees the conflict as they type instead of
        // after pressing Save.
        _ringError = exists ? 'birds.ring_number_not_unique'.tr() : null;
      });
    } catch (e, st) {
      // Don't block the user if the lookup itself fails — submit-time
      // server check is still the source of truth. Log at error with the
      // stack trace so a recurring lookup failure is diagnosable in
      // observability instead of being a context-free warning.
      AppLogger.error('Ring uniqueness check failed', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.section_identity'.tr()),
        TextFormField(
          controller: widget.ringController,
          decoration: InputDecoration(
            labelText: 'birds.ring_number'.tr(),
            border: const OutlineInputBorder(),
            errorText: _ringError,
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.ring, size: 20),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        DatePickerField(
          label: 'birds.birth_date'.tr(),
          value: widget.birthDate,
          onChanged: widget.onBirthDateChanged,
          // Relative lower bound (30 years back) instead of a fixed calendar
          // year so the selectable range doesn't silently shrink as time
          // passes — covers realistic budgie lifespans.
          firstDate: DateTime(DateTime.now().year - 30),
          lastDate: DateTime.now(),
          isRequired: false,
          dateFormatter: widget.dateFormatter,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: widget.cageController,
          decoration: InputDecoration(
            labelText: 'birds.cage_number'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.nest, size: 20),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

/// Parents section: father and mother selectors.
class BirdFormParentsSection extends StatelessWidget {
  final Species species;
  final String? fatherId;
  final String? motherId;
  final String? editBirdId;
  final ValueChanged<String?> onFatherChanged;
  final ValueChanged<String?> onMotherChanged;

  const BirdFormParentsSection({
    super.key,
    required this.species,
    required this.fatherId,
    required this.motherId,
    this.editBirdId,
    required this.onFatherChanged,
    required this.onMotherChanged,
  });

  @override
  Widget build(BuildContext context) {
    final parentSpeciesFilter = species == Species.unknown ? null : species;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.parents'.tr()),
        BirdParentSelector(
          label: 'birds.select_father'.tr(),
          icon: const AppIcon(AppIcons.male, size: 20),
          selectedId: fatherId,
          excludeId: editBirdId,
          speciesFilter: parentSpeciesFilter,
          genderFilter: BirdGender.male,
          onChanged: onFatherChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        BirdParentSelector(
          label: 'birds.select_mother'.tr(),
          icon: const AppIcon(AppIcons.female, size: 20),
          selectedId: motherId,
          excludeId: editBirdId,
          speciesFilter: parentSpeciesFilter,
          genderFilter: BirdGender.female,
          onChanged: onMotherChanged,
        ),
      ],
    );
  }
}

/// Notes section: optional notes text field.
class BirdFormNotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const BirdFormNotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: notesController,
      decoration: InputDecoration(
        labelText: 'common.notes_optional'.tr(),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      maxLines: 4,
      maxLength: 300,
      textInputAction: TextInputAction.done,
    );
  }
}
