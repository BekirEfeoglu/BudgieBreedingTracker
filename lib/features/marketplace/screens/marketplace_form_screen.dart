import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/utils/logger.dart';
import '../../../core/enums/bird_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/unsaved_changes_scope.dart';
import '../../../data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../providers/marketplace_form_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_bird_picker_sheet.dart';
import '../widgets/marketplace_image_picker.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

part 'marketplace_form_widgets.dart';

class MarketplaceFormScreen extends ConsumerStatefulWidget {
  final String? editListingId;

  const MarketplaceFormScreen({super.key, this.editListingId});

  @override
  ConsumerState<MarketplaceFormScreen> createState() =>
      _MarketplaceFormScreenState();
}

class _MarketplaceFormScreenState extends ConsumerState<MarketplaceFormScreen> {
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
  bool _isDirty = false;
  bool _submitted = false;

  bool get _isEdit => widget.editListingId != null;

  bool _prefillStarted = false;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    for (final c in [
      _titleController,
      _descriptionController,
      _priceController,
      _speciesController,
      _mutationController,
      _ageController,
      _cityController,
    ]) {
      c.addListener(_markDirty);
    }
  }

  /// Loads the existing listing in edit mode and prefills every controller +
  /// state field. Without this, opening "Edit Listing" produces a blank form
  /// and submitting overwrites the row with empty values (audit M3).
  ///
  /// Called from build() guarded by `_prefillStarted` so the request only
  /// fires once per screen lifetime — the controller listeners that flip
  /// `_isDirty` are temporarily detached during prefill so the form doesn't
  /// open in a dirty state.
  Future<void> _prefillFromExisting(String listingId, String userId) async {
    if (_prefillStarted) return;
    _prefillStarted = true;
    try {
      final listing = await ref.read(
        marketplaceListingByIdProvider((id: listingId, userId: userId)).future,
      );
      if (!mounted || listing == null) return;

      for (final c in [
        _titleController,
        _descriptionController,
        _priceController,
        _speciesController,
        _mutationController,
        _ageController,
        _cityController,
      ]) {
        c.removeListener(_markDirty);
      }
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _priceController.text = listing.price?.toString() ?? '';
      _speciesController.text = listing.species;
      _mutationController.text = listing.mutation ?? '';
      _ageController.text = listing.age ?? '';
      _cityController.text = listing.city;
      if (!mounted) return;
      setState(() {
        _listingType = listing.listingType;
        _gender = listing.gender;
        _imagePaths = List.of(listing.imageUrls);
        _linkedBirdId = listing.birdId;
        // Bird name isn't on the listing — would need a follow-up fetch.
        // Acceptable for the prefill MVP; user can re-link if needed.
      });
      for (final c in [
        _titleController,
        _descriptionController,
        _priceController,
        _speciesController,
        _mutationController,
        _ageController,
        _cityController,
      ]) {
        c.addListener(_markDirty);
      }
    } catch (e, st) {
      AppLogger.error('marketplace_form.prefill', e, st);
    }
  }

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

    if (_isEdit && !_prefillStarted) {
      final userId = ref.read(currentUserIdProvider);
      // Fire-and-forget: future completes via _prefillFromExisting and
      // calls setState to populate the form. Guarded by _prefillStarted so
      // the rebuild from setState doesn't re-trigger.
      unawaited(_prefillFromExisting(widget.editListingId!, userId));
    }

    ref.listen<MarketplaceFormState>(marketplaceFormStateProvider, (_, state) {
      if (!mounted) return;
      if (state.isSuccess) {
        _submitted = true;
        ref.read(marketplaceFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return UnsavedChangesScope(
      isDirty: _isDirty && !_submitted,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit
                ? 'marketplace.edit_listing'.tr()
                : 'marketplace.new_listing'.tr(),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  icon: const Icon(LucideIcons.tag),
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
                          avatar: selected ? null : _typeIcon(type, size: 16),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _listingType = type),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // --- Basic Info ---
                _SectionHeader(
                  icon: const Icon(LucideIcons.fileText),
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

                // Price field — only meaningful for sale listings, but
                // without this the form silently created free sale ads.
                if (_listingType == MarketplaceListingType.sale) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'marketplace.price_label'.tr(),
                      prefixIcon: const Icon(LucideIcons.dollarSign, size: 18),
                    ),
                    validator: (value) {
                      if (_listingType != MarketplaceListingType.sale) {
                        return null;
                      }
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) {
                        return 'marketplace.price_required'.tr();
                      }
                      // Accept both ',' and '.' as decimal separators
                      // so TR/DE locales aren't rejected.
                      final parsed = double.tryParse(raw.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return 'marketplace.price_required'.tr();
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),

                // --- Bird Info ---
                _SectionHeader(
                  // Audit L1: bird is a domain concept; LucideIcons is for
                  // generic UI only. Use the project's SVG asset.
                  icon: const AppIcon(AppIcons.bird),
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
                  children:
                      [
                        BirdGender.male,
                        BirdGender.female,
                        BirdGender.unknown,
                      ].map((g) {
                        final selected = _gender == g;
                        return ChoiceChip(
                          label: Text(_genderLabel(g)),
                          avatar: selected
                              ? null
                              : Icon(_genderIcon(g), size: 16),
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
                  icon: const Icon(LucideIcons.mapPin),
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
                  label: _isEdit
                      ? 'common.update'.tr()
                      : 'marketplace.publish'.tr(),
                  isLoading: formState.isLoading,
                  onPressed: _onSubmit,
                  icon: Icon(_isEdit ? LucideIcons.save : LucideIcons.send),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBird() async {
    final userId = ref.read(currentUserIdProvider);
    final bird = await showAppBottomSheet<Bird>(
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
            ? double.tryParse(_priceController.text.trim().replaceAll(',', '.'))
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
            ? double.tryParse(_priceController.text.trim().replaceAll(',', '.'))
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

  Widget _typeIcon(MarketplaceListingType type, {double? size, Color? color}) =>
      switch (type) {
        MarketplaceListingType.sale => Icon(
          LucideIcons.shoppingBag,
          size: size,
          color: color,
        ),
        MarketplaceListingType.adoption => AppIcon(
          AppIcons.heart,
          size: size,
          color: color,
        ),
        MarketplaceListingType.trade => Icon(
          LucideIcons.repeat,
          size: size,
          color: color,
        ),
        MarketplaceListingType.wanted => Icon(
          LucideIcons.search,
          size: size,
          color: color,
        ),
        MarketplaceListingType.unknown => Icon(
          LucideIcons.tag,
          size: size,
          color: color,
        ),
      };
}
