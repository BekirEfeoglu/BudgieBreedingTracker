import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../providers/marketplace_form_providers.dart';
import '../widgets/marketplace_bird_picker_sheet.dart';
import '../widgets/marketplace_image_picker.dart';

class MarketplaceFormScreen extends ConsumerStatefulWidget {
  final String? editListingId;

  const MarketplaceFormScreen({super.key, this.editListingId});

  @override
  ConsumerState<MarketplaceFormScreen> createState() =>
      _MarketplaceFormScreenState();
}

class _MarketplaceFormScreenState
    extends ConsumerState<MarketplaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _speciesController = TextEditingController();
  final _mutationController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();

  MarketplaceListingType _listingType = MarketplaceListingType.sale;
  BirdGender _gender = BirdGender.unknown;
  List<String> _imagePaths = [];
  String? _linkedBirdId;
  String? _linkedBirdName;

  bool get _isEdit => widget.editListingId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _speciesController.dispose();
    _mutationController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(marketplaceFormStateProvider);
    final theme = Theme.of(context);

    ref.listen<MarketplaceFormState>(marketplaceFormStateProvider, (_, state) {
      if (!mounted) return;
      if (state.isSuccess) {
        ref.read(marketplaceFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'marketplace.edit_listing'.tr()
              : 'marketplace.new_listing'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Photos ---
              MarketplaceImagePicker(
                imagePaths: _imagePaths,
                onChanged: (paths) => setState(() => _imagePaths = paths),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Listing Type Chips ---
              _SectionHeader(
                icon: LucideIcons.tag,
                label: 'marketplace.listing_type_label'.tr(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: MarketplaceListingType.values
                    .where((t) => t != MarketplaceListingType.unknown)
                    .map((type) {
                  final selected = _listingType == type;
                  return ChoiceChip(
                    label: Text(_typeLabel(type)),
                    avatar: selected
                        ? null
                        : Icon(_typeIcon(type), size: 16),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _listingType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Basic Info ---
              _SectionHeader(
                icon: LucideIcons.fileText,
                label: 'marketplace.section_basic'.tr(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'marketplace.title_label'.tr(),
                  prefixIcon: const Icon(LucideIcons.type, size: 18),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.title_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'marketplace.description_label'.tr(),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 52),
                    child: Icon(LucideIcons.alignLeft, size: 18),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 2000,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.description_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Price (only for sale) ---
              if (_listingType == MarketplaceListingType.sale) ...[
                _SectionHeader(
                  icon: LucideIcons.banknote,
                  label: 'marketplace.price_label'.tr(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'marketplace.price_label'.tr(),
                    prefixIcon: const Icon(LucideIcons.banknote, size: 18),
                    suffixText: '\u20BA',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: (value) {
                    if (_listingType == MarketplaceListingType.sale &&
                        (value == null || value.trim().isEmpty)) {
                      return 'marketplace.price_required'.tr();
                    }
                    if (value != null && value.trim().isNotEmpty) {
                      final price = double.tryParse(value.trim());
                      if (price == null || price <= 0 || price > 999999) {
                        return 'validation.invalid_price'.tr();
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // --- Bird Info ---
              _SectionHeader(
                icon: LucideIcons.bird,
                label: 'marketplace.section_bird'.tr(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Link bird button / chip
              _LinkedBirdCard(
                linkedBirdId: _linkedBirdId,
                linkedBirdName: _linkedBirdName,
                onPick: _pickBird,
                onClear: () => setState(() {
                  _linkedBirdId = null;
                  _linkedBirdName = null;
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _speciesController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'marketplace.species_label'.tr(),
                  prefixIcon: const AppIcon(AppIcons.bird, size: 18),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.species_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _mutationController,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'marketplace.mutation_label'.tr(),
                  prefixIcon: const AppIcon(AppIcons.dna, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Gender chips
              Text(
                'marketplace.gender_label'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [BirdGender.male, BirdGender.female, BirdGender.unknown]
                    .map((g) {
                  final selected = _gender == g;
                  return ChoiceChip(
                    label: Text(_genderLabel(g)),
                    avatar: selected ? null : Icon(_genderIcon(g), size: 16),
                    selected: selected,
                    onSelected: (_) => setState(() => _gender = g),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _ageController,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'marketplace.age_label'.tr(),
                  prefixIcon: const Icon(LucideIcons.calendar, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // --- Location ---
              _SectionHeader(
                icon: LucideIcons.mapPin,
                label: 'marketplace.city_label'.tr(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'marketplace.city_label'.tr(),
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.city_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // --- Submit ---
              PrimaryButton(
                label: _isEdit ? 'common.update'.tr() : 'marketplace.publish'.tr(),
                isLoading: formState.isLoading,
                onPressed: _onSubmit,
                icon: Icon(
                  _isEdit ? LucideIcons.save : LucideIcons.send,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBird() async {
    final userId = ref.read(currentUserIdProvider);
    final bird = await showModalBottomSheet<Bird>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MarketplaceBirdPickerSheet(userId: userId),
    );
    if (bird != null && mounted) {
      setState(() {
        _linkedBirdId = bird.id;
        _linkedBirdName = bird.name;
        _speciesController.text = bird.species.name;
        if (bird.colorMutation != null &&
            bird.colorMutation != BirdColor.unknown) {
          _mutationController.text = bird.colorMutation!.name;
        }
        _gender = bird.gender;
      });
    }
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(marketplaceFormStateProvider.notifier);

    if (_isEdit) {
      notifier.updateListing(
        listingId: widget.editListingId!,
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _listingType == MarketplaceListingType.sale
            ? double.tryParse(_priceController.text.trim())
            : null,
        birdId: _linkedBirdId,
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        localImagePaths: _imagePaths,
        city: _cityController.text.trim(),
      );
    } else {
      notifier.createListing(
        userId: userId,
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _listingType == MarketplaceListingType.sale
            ? double.tryParse(_priceController.text.trim())
            : null,
        birdId: _linkedBirdId,
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        localImagePaths: _imagePaths,
        city: _cityController.text.trim(),
      );
    }
  }

  String _genderLabel(BirdGender gender) => switch (gender) {
        BirdGender.male => 'birds.male'.tr(),
        BirdGender.female => 'birds.female'.tr(),
        _ => 'marketplace.gender_unknown'.tr(),
      };

  IconData _genderIcon(BirdGender gender) => switch (gender) {
        BirdGender.male => LucideIcons.arrowUpRight,
        BirdGender.female => LucideIcons.arrowDownRight,
        _ => LucideIcons.helpCircle,
      };

  String _typeLabel(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => 'marketplace.type_sale'.tr(),
        MarketplaceListingType.adoption => 'marketplace.type_adoption'.tr(),
        MarketplaceListingType.trade => 'marketplace.type_trade'.tr(),
        MarketplaceListingType.wanted => 'marketplace.type_wanted'.tr(),
        MarketplaceListingType.unknown => '',
      };

  IconData _typeIcon(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => LucideIcons.shoppingBag,
        MarketplaceListingType.adoption => LucideIcons.heart,
        MarketplaceListingType.trade => LucideIcons.repeat,
        MarketplaceListingType.wanted => LucideIcons.search,
        MarketplaceListingType.unknown => LucideIcons.tag,
      };
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _LinkedBirdCard extends StatelessWidget {
  const _LinkedBirdCard({
    required this.linkedBirdId,
    required this.linkedBirdName,
    required this.onPick,
    required this.onClear,
  });

  final String? linkedBirdId;
  final String? linkedBirdName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (linkedBirdId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              AppIcons.bird,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'marketplace.linked_bird'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    linkedBirdName ?? linkedBirdId!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onClear,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const AppIcon(AppIcons.bird, size: 18),
      label: Text('marketplace.select_bird'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSpacing.touchTargetMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
