import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../providers/marketplace_form_providers.dart';

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
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<MarketplaceListingType>(
                initialValue: _listingType,
                decoration: InputDecoration(
                  labelText: 'marketplace.listing_type_label'.tr(),
                ),
                items: MarketplaceListingType.values
                    .where((t) => t != MarketplaceListingType.unknown)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _listingType = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'marketplace.title_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.title_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'marketplace.description_label'.tr(),
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
              const SizedBox(height: AppSpacing.lg),
              if (_listingType == MarketplaceListingType.sale) ...[
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'marketplace.price_label'.tr(),
                    suffixText: 'TRY',
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
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _speciesController,
                decoration: InputDecoration(
                  labelText: 'marketplace.species_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.species_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _mutationController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'marketplace.mutation_label'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<BirdGender>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'marketplace.gender_label'.tr(),
                ),
                items: [BirdGender.male, BirdGender.female, BirdGender.unknown]
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(_genderLabel(g)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _gender = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _ageController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'marketplace.age_label'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'marketplace.city_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.city_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: _isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                isLoading: formState.isLoading,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
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
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        imageUrls: const [],
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
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        imageUrls: const [],
        city: _cityController.text.trim(),
      );
    }
  }

  String _genderLabel(BirdGender gender) => switch (gender) {
        BirdGender.male => 'birds.male'.tr(),
        BirdGender.female => 'birds.female'.tr(),
        _ => 'marketplace.gender_unknown'.tr(),
      };

  String _typeLabel(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => 'marketplace.type_sale'.tr(),
        MarketplaceListingType.adoption => 'marketplace.type_adoption'.tr(),
        MarketplaceListingType.trade => 'marketplace.type_trade'.tr(),
        MarketplaceListingType.wanted => 'marketplace.type_wanted'.tr(),
        MarketplaceListingType.unknown => '',
      };
}
