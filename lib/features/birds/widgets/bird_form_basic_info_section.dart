import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_color_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Basic info section: name, gender, species, color mutation.
class BirdFormBasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final BirdGender gender;
  final Species species;
  final BirdColor? colorMutation;
  final TextEditingController colorNoteController;
  final XFile? photoFile;
  final bool showPhotoPicker;
  final VoidCallback? onPickPhotoSource;
  final VoidCallback? onRemovePhoto;
  final ValueChanged<BirdGender> onGenderChanged;
  final ValueChanged<Species> onSpeciesChanged;
  final ValueChanged<BirdColor?> onColorChanged;

  const BirdFormBasicInfoSection({
    super.key,
    required this.nameController,
    required this.gender,
    required this.species,
    required this.colorMutation,
    required this.colorNoteController,
    this.photoFile,
    this.showPhotoPicker = false,
    this.onPickPhotoSource,
    this.onRemovePhoto,
    required this.onGenderChanged,
    required this.onSpeciesChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final profile = SpeciesRegistry.of(species);
    final normalizedColorMutation = colorMutation == BirdColor.unknown
        ? null
        : colorMutation;
    final supportedSpecies = SpeciesRegistry.supportedSpecies;
    final selectableSpecies = supportedSpecies;
    final selectedSpecies = selectableSpecies.contains(species)
        ? species
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.section_basic'.tr()),
        if (showPhotoPicker) ...[
          _BirdFormPhotoPicker(
            photoFile: photoFile,
            onPickPhotoSource: onPickPhotoSource,
            onRemovePhoto: onRemovePhoto,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'birds.name_label'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.bird, size: 20),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'birds.name_required'.tr();
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'birds.gender'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<BirdGender>(
          showSelectedIcon: false,
          style: ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              const Size(0, AppSpacing.touchTargetLg),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
          segments: [
            ButtonSegment(
              value: BirdGender.male,
              label: _GenderSegmentLabel(
                icon: const AppIcon(AppIcons.male, size: 20),
                label: 'birds.male'.tr(),
              ),
              tooltip: 'birds.male'.tr(),
            ),
            ButtonSegment(
              value: BirdGender.female,
              label: _GenderSegmentLabel(
                icon: const AppIcon(AppIcons.female, size: 20),
                label: 'birds.female'.tr(),
              ),
              tooltip: 'birds.female'.tr(),
            ),
            ButtonSegment(
              value: BirdGender.unknown,
              label: _GenderSegmentLabel(
                icon: const Icon(LucideIcons.helpCircle, size: 20),
                label: 'birds.unknown'.tr(),
              ),
              tooltip: 'birds.unknown'.tr(),
            ),
          ],
          selected: {gender},
          onSelectionChanged: (selection) {
            onGenderChanged(selection.first);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<Species>(
          initialValue: selectedSpecies,
          decoration: InputDecoration(
            labelText: 'birds.species'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: speciesIconWidget(species, size: 24),
            ),
          ),
          hint: Text(
            'birds.select_species'.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          items: selectableSpecies
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      speciesIconWidget(s, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(speciesLabel(s)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onSpeciesChanged(value);
            }
          },
          validator: (value) {
            if (value == null) return 'birds.species_required'.tr();
            return null;
          },
          isExpanded: true,
        ),
        if (selectedSpecies != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.helpTextKey.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<BirdColor?>(
          initialValue: normalizedColorMutation,
          decoration: InputDecoration(
            labelText: 'birds.color'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.colorPalette, size: 20),
            ),
          ),
          items: [
            DropdownMenuItem<BirdColor?>(
              value: null,
              child: Text(
                'birds.no_color_selected'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...profile.supportedColors.map(
              (color) => DropdownMenuItem<BirdColor?>(
                value: color,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: birdColorToColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(birdColorLabel(color)),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            onColorChanged(value);
          },
          isExpanded: true,
        ),
        if (colorMutation == BirdColor.other) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: colorNoteController,
            decoration: InputDecoration(
              labelText: 'birds.color_name'.tr(),
              border: const OutlineInputBorder(),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: AppIcon(AppIcons.colorPalette, size: 20),
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'validation.field_required'.tr(
                  args: ['birds.color_name'.tr()],
                );
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

class _BirdFormPhotoPicker extends StatelessWidget {
  final XFile? photoFile;
  final VoidCallback? onPickPhotoSource;
  final VoidCallback? onRemovePhoto;

  const _BirdFormPhotoPicker({
    required this.photoFile,
    required this.onPickPhotoSource,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = photoFile;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            width: 72,
            height: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: photo == null
                ? Icon(
                    LucideIcons.camera,
                    size: 28,
                    color: theme.colorScheme.primary,
                  )
                : _SelectedPhotoPreview(photo: photo),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onPickPhotoSource,
                icon: const AppIcon(AppIcons.photo, size: 18),
                label: Text(
                  photo == null ? 'birds.add_photo'.tr() : 'common.edit'.tr(),
                ),
              ),
              if (photo != null)
                TextButton.icon(
                  onPressed: onRemovePhoto,
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: Text('common.delete'.tr()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  final XFile photo;

  const _SelectedPhotoPreview({required this.photo});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: photo.readAsBytes(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}

class _GenderSegmentLabel extends StatelessWidget {
  final Widget icon;
  final String label;

  const _GenderSegmentLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 22, child: Center(child: icon)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, maxLines: 1),
        ],
      ),
    );
  }
}
