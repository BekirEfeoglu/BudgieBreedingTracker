import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/marketplace_providers.dart';

class MarketplaceFilterSheet extends ConsumerStatefulWidget {
  const MarketplaceFilterSheet({super.key});

  @override
  ConsumerState<MarketplaceFilterSheet> createState() =>
      _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState
    extends ConsumerState<MarketplaceFilterSheet> {
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _cityController = TextEditingController();
  BirdGender? _selectedGender;

  @override
  void initState() {
    super.initState();
    final range = ref.read(marketplacePriceRangeProvider);
    if (range.min != null) {
      _minPriceController.text = range.min!.toStringAsFixed(0);
    }
    if (range.max != null) {
      _maxPriceController.text = range.max!.toStringAsFixed(0);
    }
    _cityController.text = ref.read(marketplaceCityFilterProvider) ?? '';
    _selectedGender = ref.read(marketplaceGenderFilterProvider);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _apply() {
    final minText = _minPriceController.text.trim();
    final maxText = _maxPriceController.text.trim();
    final city = _cityController.text.trim();

    ref.read(marketplacePriceRangeProvider.notifier).state = (
      min: minText.isNotEmpty ? double.tryParse(minText) : null,
      max: maxText.isNotEmpty ? double.tryParse(maxText) : null,
    );
    ref.read(marketplaceCityFilterProvider.notifier).state =
        city.isNotEmpty ? city : null;
    ref.read(marketplaceGenderFilterProvider.notifier).state = _selectedGender;

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(marketplacePriceRangeProvider.notifier).state =
        (min: null, max: null);
    ref.read(marketplaceCityFilterProvider.notifier).state = null;
    ref.read(marketplaceGenderFilterProvider.notifier).state = null;

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    LucideIcons.slidersHorizontal,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'marketplace.filter_results'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price range section
              Text(
                'marketplace.price_range'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'marketplace.min_price'.tr(),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'marketplace.max_price'.tr(),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // City section
              Text(
                'marketplace.city_label'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'marketplace.city_filter'.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Gender filter section
              Text(
                'marketplace.gender_filter'.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: Text('birds.male'.tr()),
                    selected: _selectedGender == BirdGender.male,
                    onSelected: (_) {
                      setState(() {
                        _selectedGender = _selectedGender == BirdGender.male
                            ? null
                            : BirdGender.male;
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                  FilterChip(
                    label: Text('birds.female'.tr()),
                    selected: _selectedGender == BirdGender.female,
                    onSelected: (_) {
                      setState(() {
                        _selectedGender = _selectedGender == BirdGender.female
                            ? null
                            : BirdGender.female;
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                  FilterChip(
                    label: Text('marketplace.gender_unknown'.tr()),
                    selected: _selectedGender == BirdGender.unknown,
                    onSelected: (_) {
                      setState(() {
                        _selectedGender = _selectedGender == BirdGender.unknown
                            ? null
                            : BirdGender.unknown;
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      child: Text('marketplace.clear_filters'.tr()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: Text('marketplace.apply_filters'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
